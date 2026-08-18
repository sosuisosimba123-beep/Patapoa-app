<?php

namespace App\Services;

use GuzzleHttp\Client;
use Illuminate\Support\Facades\Log;

class AiStandardizationService
{
    protected $client;
    protected $apiKey;
    protected $model = 'gemini-1.5-flash';

    public function __construct()
    {
        $this->client = new Client();
        $this->apiKey = env('GEMINI_API_KEY');
    }

    /**
     * Standardizes a raw product input string into a structured array.
     */
    public function standardizeProduct(string $rawInput): ?array
    {
        if (strlen(trim($rawInput)) < 3) {
            return null;
        }

        try {
            $prompt = $this->getCatalogCleanupPrompt($rawInput);

            $url = "https://generativelanguage.googleapis.com/v1beta/models/{$this->model}:generateContent?key={$this->apiKey}";

            $response = $this->client->post($url, [
                'json' => [
                    'contents' => [
                        [
                            'parts' => [
                                ['text' => $prompt]
                            ]
                        ]
                    ]
                ],
                'timeout' => 5
            ]);

            $result = json_decode($response->getBody()->getContents(), true);
            $text = $result['candidates'][0]['content']['parts'][0]['text'] ?? null;

            if ($text) {
                // Remove markdown code blocks if present
                $jsonStr = trim(str_replace(['```json', '```'], '', $text));
                $data = json_decode($jsonStr, true);

                if (json_last_error() === JSON_ERROR_NONE && ($data['is_valid'] ?? false)) {
                    return $data;
                }
            }
        } catch (\Exception $e) {
            Log::error('AI Standardization Failed: ' . $e->getMessage());
        }

        return $this->localFallback($rawInput);
    }

    protected function getCatalogCleanupPrompt(string $input): string
    {
        return <<<PROMPT
You are a product catalog expert for Patapoa, a marketplace in Tanzania.
Standardize this raw merchant input: "$input"

RULES:
1. Standardize and capitalize the "product_name".
2. Extract the "brand" if mentioned (e.g., "Azam", "Mo", "Kilombero").
3. Extract standardized "size" (e.g., "1kg", "500ml").
4. Suggest a "high_quality_image_url" that is a professional, high-resolution product shot (prefer clean white backgrounds).
5. Set "is_valid" to true if recognizable.

OUTPUT ONLY JSON:
{
  "product_name": "string",
  "brand": "string|null",
  "size": "string",
  "high_quality_image_url": "string",
  "is_valid": boolean
}
PROMPT;
    }

    protected function localFallback(string $input): array
    {
        $name = ucwords(strtolower(trim($input)));
        $size = '';
        $brand = null;
        $image = 'https://patapoa.co.tz/images/default-product.png'; // Clean default

        $lower = strtolower($input);

        // Simple brand detection for common TZ brands
        $brands = ['azam', 'mo', 'kilombero', 'tpc', 'kagera', 'asas', 'bakhresa'];
        foreach ($brands as $b) {
            if (str_contains($lower, $b)) {
                $brand = ucfirst($b);
                break;
            }
        }

        // Basic size regex
        if (preg_match('/(\d+(\.\d+)?\s*(kg|g|ml|l|ltr))/i', $lower, $matches)) {
            $size = strtoupper($matches[0]);
        }

        return [
            'product_name' => $name,
            'brand' => $brand,
            'size' => $size,
            'high_quality_image_url' => $image,
            'is_valid' => strlen($name) > 2
        ];
    }
}
