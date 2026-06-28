<?php

namespace App\Http\Traits;

use Illuminate\Database\Eloquent\Builder;

trait SelectiveFields
{
    /**
     * Apply selective field loading to a query.
     * Supports comma-separated fields via ?fields= query parameter.
     *
     * @param Builder $query
     * @param array<string> $defaultFields Fields to select if none specified
     * @param array<string> $allowedFields Whitelist of selectable fields (empty = all allowed)
     * @param array<string> $requiredFields Fields always included (e.g. primary keys)
     * @return Builder
     */
    protected function applyFields(
        Builder $query,
        array $defaultFields = ['*'],
        array $allowedFields = [],
        array $requiredFields = ['id']
    ): Builder {
        $request = request();
        
        if (!$request->has('fields')) {
            return $query->select($defaultFields);
        }

        $requestedFields = array_map('trim', explode(',', $request->get('fields')));
        
        // If allowed fields is specified, filter to only those
        if (!empty($allowedFields)) {
            $requestedFields = array_intersect($requestedFields, $allowedFields);
        }

        // Always include required fields
        $fields = array_unique(array_merge($requiredFields, $requestedFields));

        // Ensure we don't send an empty select
        if (empty($fields)) {
            $fields = $defaultFields;
        }

        return $query->select($fields);
    }

    /**
     * Apply selective relation loading with field selection.
     * Usage: ?with=merchant:fields(name,logo)&with=category:fields(name)
     *
     * @param Builder $query
     * @param array<string> $allowedRelations Whitelist of loadable relations
     * @return Builder
     */
    protected function applyWithRelations(Builder $query, array $allowedRelations = []): Builder
    {
        $request = request();
        
        if (!$request->has('with')) {
            return $query;
        }

        $with = $request->get('with');
        $relations = is_array($with) ? $with : [$with];
        
        foreach ($relations as $relation) {
            // Parse "relation:fields(field1,field2)" syntax
            if (str_contains($relation, ':fields(')) {
                preg_match('/^(.*?):fields\((.*?)\)$/', $relation, $matches);
                if ($matches) {
                    $relationName = $matches[1];
                    $fields = array_map('trim', explode(',', $matches[2]));
                    
                    if (empty($allowedRelations) || in_array($relationName, $allowedRelations)) {
                        $query->with([$relationName => function ($q) use ($fields) {
                            $q->select(array_merge(['id'], $fields));
                        }]);
                    }
                }
            } else {
                if (empty($allowedRelations) || in_array($relation, $allowedRelations)) {
                    $query->with($relation);
                }
            }
        }

        return $query;
    }
}
