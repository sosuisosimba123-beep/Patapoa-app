<?php

namespace App\Services;

class ProductEnrichmentService
{
    protected $ai;

    public function __construct(AiStandardizationService $ai)
    {
        $this->ai = $ai;
    }

    /**
     * Enrich product data using Gemini AI.
     */
    public function enrich(string $name, ?string $barcode = null): array
    {
        $data = [
            'name' => $name,
            'brand' => null,
            'image_url' => null,
            'size' => null,
        ];

        // Use Gemini for high-quality data and professional image extraction
        // If name is empty (barcode scan), we tell AI to identify from barcode or provided name
        $aiData = $this->ai->standardizeProduct($name ?: ($barcode ? "Product with barcode $barcode" : ""));

        if ($aiData) {
            $data['name'] = $aiData['product_name'] ?? $data['name'];
            $data['size'] = $aiData['size'] ?? $data['size'];
            $data['image_url'] = $aiData['high_quality_image_url'] ?? $data['image_url'];
            $data['brand'] = $aiData['brand'] ?? null;
        }

        return $data;
    }
}
