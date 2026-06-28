<?php

namespace App\Http\Traits;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;

trait HasPagination
{
    /**
     * Paginate a query with consistent page/limit parameters.
     *
     * @param Builder $query
     * @param Request $request
     * @param int $defaultLimit
     * @param int $maxLimit
     * @return \Illuminate\Contracts\Pagination\LengthAwarePaginator
     */
    protected function paginateQuery(Builder $query, Request $request, int $defaultLimit = 20, int $maxLimit = 100)
    {
        $limit = min(
            (int) $request->get('limit', $defaultLimit),
            $maxLimit
        );
        $page = max((int) $request->get('page', 1), 1);

        return $query->paginate($limit, ['*'], 'page', $page);
    }

    /**
     * Get pagination meta for frontend consumption.
     *
     * @param \Illuminate\Contracts\Pagination\LengthAwarePaginator $paginator
     * @return array
     */
    protected function paginationMeta($paginator): array
    {
        return [
            'current_page' => $paginator->currentPage(),
            'last_page' => $paginator->lastPage(),
            'per_page' => $paginator->perPage(),
            'total' => $paginator->total(),
            'from' => $paginator->firstItem(),
            'to' => $paginator->lastItem(),
            'has_more' => $paginator->hasMorePages(),
        ];
    }
}
