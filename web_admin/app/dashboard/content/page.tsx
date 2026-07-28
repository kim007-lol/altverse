"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Search, EyeOff, Eye } from "lucide-react";

interface Series {
  id: number; title: string; author_id: number; author_name: string;
  status: string; total_views: number; total_likes: number;
  ep_count: number; created_at: string; deleted_at: string | null;
}

export default function ContentPage() {
  const qc = useQueryClient();
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [page, setPage] = useState(1);
  const [pendingId, setPendingId] = useState<number | null>(null);

  const { data, isLoading } = useQuery<{ data: Series[]; meta: { total: number; last_page: number; page: number } }>({
    queryKey: ["admin-content", search, statusFilter, page],
    queryFn: async () => {
      const params = new URLSearchParams({ page: String(page), per_page: "20" });
      if (search) params.set("search", search);
      if (statusFilter !== "all") params.set("status", statusFilter);
      const { data } = await api.get(`/admin/content?${params}`);
      return data;
    },
  });

  const takedownMut = useMutation({
    mutationFn: (id: number) => { setPendingId(id); return api.post(`/admin/content/series/${id}/takedown`); },
    onSuccess: () => { toast.success("Series taken down"); qc.invalidateQueries({ queryKey: ["admin-content"] }); setPendingId(null); },
    onError: () => { toast.error("Failed to take down series"); setPendingId(null); },
  });

  const restoreMut = useMutation({
    mutationFn: (id: number) => { setPendingId(id); return api.post(`/admin/content/series/${id}/restore`); },
    onSuccess: () => { toast.success("Series restored"); qc.invalidateQueries({ queryKey: ["admin-content"] }); setPendingId(null); },
    onError: () => { toast.error("Failed to restore series"); setPendingId(null); },
  });

  const series = data?.data ?? [];

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Content Moderation</h1>

      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-48">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search title or author…"
            className="pl-8"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
          />
        </div>
        <Select value={statusFilter} onValueChange={(v) => { if (v) { setStatusFilter(v); setPage(1); } }}>
          <SelectTrigger className="w-44">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="published">Published</SelectItem>
            <SelectItem value="draft">Draft</SelectItem>
            <SelectItem value="taken_down">Taken Down</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm text-muted-foreground">
            {data?.meta ? `${data.meta.total} series total` : "Loading…"}
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="space-y-2 p-4">
              {Array.from({ length: 8 }).map((_, i) => <Skeleton key={i} className="h-10 w-full" />)}
            </div>
          ) : series.length === 0 ? (
            <p className="p-6 text-center text-sm text-muted-foreground">No series found.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b bg-muted/50 text-left text-xs text-muted-foreground">
                    <th className="px-4 py-2.5">Series</th>
                    <th className="px-4 py-2.5">Author</th>
                    <th className="px-4 py-2.5">Episodes</th>
                    <th className="px-4 py-2.5">Views</th>
                    <th className="px-4 py-2.5">Status</th>
                    <th className="px-4 py-2.5">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {series.map((s) => {
                    const takenDown = s.deleted_at !== null;
                    return (
                      <tr key={s.id} className="border-b last:border-0 hover:bg-muted/30">
                        <td className="px-4 py-3 font-medium max-w-xs">
                          <p className="truncate">{s.title}</p>
                        </td>
                        <td className="px-4 py-3 text-muted-foreground">{s.author_name}</td>
                        <td className="px-4 py-3">{s.ep_count}</td>
                        <td className="px-4 py-3 font-mono">{s.total_views.toLocaleString()}</td>
                        <td className="px-4 py-3">
                          {takenDown ? (
                            <Badge variant="destructive">Taken Down</Badge>
                          ) : (
                            <Badge variant={s.status === "published" ? "default" : "outline"} className="capitalize">
                              {s.status}
                            </Badge>
                          )}
                        </td>
                        <td className="px-4 py-3">
                          {takenDown ? (
                            <Button
                              size="sm" variant="outline" className="gap-1.5"
                              onClick={() => restoreMut.mutate(s.id)}
                              disabled={pendingId === s.id}
                            >
                              <Eye size={13} /> Restore
                            </Button>
                          ) : (
                            <Button
                              size="sm" variant="outline"
                              className="gap-1.5 text-destructive hover:bg-destructive/10 hover:text-destructive"
                              onClick={() => takedownMut.mutate(s.id)}
                              disabled={pendingId === s.id}
                            >
                              <EyeOff size={13} /> Takedown
                            </Button>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {data?.meta && data.meta.last_page > 1 && (
        <div className="flex items-center justify-between text-sm">
          <span className="text-muted-foreground">Page {data.meta.page} of {data.meta.last_page}</span>
          <div className="flex gap-2">
            <Button size="sm" variant="outline" onClick={() => setPage((p) => p - 1)} disabled={page === 1}>Previous</Button>
            <Button size="sm" variant="outline" onClick={() => setPage((p) => p + 1)} disabled={page === data.meta.last_page}>Next</Button>
          </div>
        </div>
      )}
    </div>
  );
}
