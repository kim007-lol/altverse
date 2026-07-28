"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Search, ShieldCheck } from "lucide-react";

interface AuditLog {
  id: number; admin_id: number; admin_name: string; action: string;
  target_type: string; target_id: string; detail: string;
  ip_address: string; status_code: number; created_at: string;
}

function statusVariant(code: number): "default" | "secondary" | "destructive" | "outline" {
  if (code >= 500) return "destructive";
  if (code >= 400) return "secondary";
  return "default";
}

export default function AuditPage() {
  const [actionFilter, setActionFilter] = useState("");
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery<{ data: AuditLog[]; meta: { total: number; last_page: number; page: number } }>({
    queryKey: ["audit-logs", actionFilter, page],
    queryFn: async () => {
      const params = new URLSearchParams({ page: String(page), per_page: "25" });
      if (actionFilter) params.set("action", actionFilter);
      const { data } = await api.get(`/admin/audit-logs?${params}`);
      return data;
    },
  });

  const logs = data?.data ?? [];

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <ShieldCheck size={20} />
        <h1 className="text-2xl font-bold">Audit Log</h1>
      </div>
      <p className="text-sm text-muted-foreground">Every mutating admin action is recorded here automatically.</p>

      <div className="relative max-w-xs">
        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
        <Input
          placeholder="Filter by action…"
          className="pl-8"
          value={actionFilter}
          onChange={(e) => { setActionFilter(e.target.value); setPage(1); }}
        />
      </div>

      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm text-muted-foreground">
            {data?.meta ? `${data.meta.total} log entries` : "Loading…"}
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="space-y-2 p-4">
              {Array.from({ length: 8 }).map((_, i) => <Skeleton key={i} className="h-10 w-full" />)}
            </div>
          ) : logs.length === 0 ? (
            <p className="p-6 text-center text-sm text-muted-foreground">No audit logs found.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b bg-muted/50 text-left text-xs text-muted-foreground">
                    <th className="px-4 py-2.5">Admin</th>
                    <th className="px-4 py-2.5">Action</th>
                    <th className="px-4 py-2.5">Target</th>
                    <th className="px-4 py-2.5">Status</th>
                    <th className="px-4 py-2.5">IP</th>
                    <th className="px-4 py-2.5">Time</th>
                  </tr>
                </thead>
                <tbody>
                  {logs.map((log) => (
                    <tr key={log.id} className="border-b last:border-0 hover:bg-muted/30">
                      <td className="px-4 py-3">
                        <p className="font-medium">{log.admin_name}</p>
                        <p className="text-xs text-muted-foreground font-mono">#{log.admin_id}</p>
                      </td>
                      <td className="px-4 py-3">
                        <code className="rounded bg-muted px-1.5 py-0.5 text-xs">{log.action}</code>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {log.target_type && <span className="capitalize">{log.target_type}</span>}
                        {log.target_id && <span className="ml-1 font-mono text-xs">#{log.target_id}</span>}
                      </td>
                      <td className="px-4 py-3">
                        <Badge variant={statusVariant(log.status_code)}>{log.status_code}</Badge>
                      </td>
                      <td className="px-4 py-3 font-mono text-xs text-muted-foreground">{log.ip_address}</td>
                      <td className="px-4 py-3 text-xs text-muted-foreground whitespace-nowrap">
                        {new Date(log.created_at).toLocaleString()}
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
