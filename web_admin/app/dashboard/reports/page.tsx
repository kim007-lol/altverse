"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { CheckCircle, XCircle } from "lucide-react";

interface Report {
  id: number; reporter_id: number; reporter_name: string;
  target_type: string; target_id: number; reason: string;
  status: string; created_at: string;
}

export default function ReportsPage() {
  const qc = useQueryClient();
  const [statusFilter, setStatusFilter] = useState("pending");
  const [page, setPage] = useState(1);
  const [pendingReportId, setPendingReportId] = useState<number | null>(null);

  const { data, isLoading } = useQuery<{ data: Report[]; meta: { total: number; last_page: number; page: number } }>({
    queryKey: ["admin-reports", statusFilter, page],
    queryFn: async () => {
      const params = new URLSearchParams({ page: String(page), per_page: "20" });
      if (statusFilter !== "all") params.set("status", statusFilter);
      const { data } = await api.get(`/admin/reports?${params}`);
      return data;
    },
  });

  const resolveMut = useMutation({
    mutationFn: ({ id, status }: { id: number; status: string }) => {
      setPendingReportId(id);
      return api.post(`/admin/reports/${id}/resolve`, { status });
    },
    onSuccess: () => {
      toast.success("Report updated");
      qc.invalidateQueries({ queryKey: ["admin-reports"] });
      setPendingReportId(null);
    },
    onError: () => {
      toast.error("Failed to update report");
      setPendingReportId(null);
    },
  });

  const statusColor: Record<string, "default" | "secondary" | "destructive" | "outline"> = {
    pending: "destructive", resolved: "default", dismissed: "secondary",
  };

  const reports = data?.data ?? [];

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Report Management</h1>

      <Select value={statusFilter} onValueChange={(v) => { if (v) { setStatusFilter(v); setPage(1); } }}>
        <SelectTrigger className="w-44">
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">All Reports</SelectItem>
          <SelectItem value="pending">Pending</SelectItem>
          <SelectItem value="resolved">Resolved</SelectItem>
          <SelectItem value="dismissed">Dismissed</SelectItem>
        </SelectContent>
      </Select>

      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm text-muted-foreground">
            {data?.meta ? `${data.meta.total} reports` : "Loading…"}
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="space-y-2 p-4">
              {Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-12 w-full" />)}
            </div>
          ) : reports.length === 0 ? (
            <p className="p-6 text-center text-sm text-muted-foreground">No reports found.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b bg-muted/50 text-left text-xs text-muted-foreground">
                    <th className="px-4 py-2.5">Reporter</th>
                    <th className="px-4 py-2.5">Target</th>
                    <th className="px-4 py-2.5">Reason</th>
                    <th className="px-4 py-2.5">Status</th>
                    <th className="px-4 py-2.5">Date</th>
                    <th className="px-4 py-2.5">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {reports.map((r) => (
                    <tr key={r.id} className="border-b last:border-0 hover:bg-muted/30">
                      <td className="px-4 py-3 font-medium">{r.reporter_name}</td>
                      <td className="px-4 py-3">
                        <span className="capitalize text-muted-foreground">{r.target_type}</span>
                        <span className="ml-1 font-mono text-xs">#{r.target_id}</span>
                      </td>
                      <td className="px-4 py-3 max-w-xs">
                        <p className="truncate text-muted-foreground">{r.reason}</p>
                      </td>
                      <td className="px-4 py-3">
                        <Badge variant={statusColor[r.status] ?? "outline"}>{r.status}</Badge>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground text-xs">
                        {new Date(r.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3">
                        {r.status === "pending" && (
                          <div className="flex gap-1.5">
                            <Button
                              size="sm" variant="outline" className="gap-1"
                              onClick={() => resolveMut.mutate({ id: r.id, status: "resolved" })}
                              disabled={pendingReportId === r.id}
                            >
                              <CheckCircle size={12} /> Resolve
                            </Button>
                            <Button
                              size="sm" variant="ghost" className="gap-1 text-muted-foreground"
                              onClick={() => resolveMut.mutate({ id: r.id, status: "dismissed" })}
                              disabled={pendingReportId === r.id}
                            >
                              <XCircle size={12} /> Dismiss
                            </Button>
                          </div>
                        )}
                      </td>
                    </tr>
                  ))}
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
