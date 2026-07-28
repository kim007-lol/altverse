"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { CheckCircle } from "lucide-react";

interface Withdrawal {
  id: number; user_id: number; author_name: string;
  amount_idr: number; bank_name: string; account_number: string;
  account_name: string; status: string; notes: string | null; created_at: string;
}

function formatIDR(n: number) {
  return new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", maximumFractionDigits: 0 }).format(n);
}

export default function WithdrawalsPage() {
  const qc = useQueryClient();
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState("pending");
  const [processing, setProcessing] = useState<Withdrawal | null>(null);
  const [adminNote, setAdminNote] = useState("");

  const { data, isLoading } = useQuery<{ data: Withdrawal[]; meta: { total: number; last_page: number; page: number } }>({
    queryKey: ["admin-withdrawals", page, statusFilter],
    queryFn: async () => {
      const params = new URLSearchParams({ page: String(page), per_page: "20" });
      if (statusFilter !== "all") params.set("status", statusFilter);
      const { data } = await api.get(`/admin/withdrawals?${params}`);
      return data;
    },
  });

  const processMut = useMutation({
    mutationFn: ({ id, status, note }: { id: number; status: string; note: string }) =>
      api.post(`/admin/withdrawals/${id}/process`, { approved: status === "success", notes: note }),
    onSuccess: () => {
      toast.success("Withdrawal processed");
      qc.invalidateQueries({ queryKey: ["admin-withdrawals"] });
      setProcessing(null);
      setAdminNote("");
    },
    onError: () => toast.error("Failed to process withdrawal"),
  });

  const withdrawals = data?.data ?? [];
  const statusVariant: Record<string, "default" | "secondary" | "destructive" | "outline"> = {
    pending: "destructive", success: "default", rejected: "secondary",
  };

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Withdrawal Requests</h1>

      <Select value={statusFilter} onValueChange={(v) => { if (v) { setStatusFilter(v); setPage(1); } }}>
        <SelectTrigger className="w-40"><SelectValue /></SelectTrigger>
        <SelectContent>
          <SelectItem value="pending">Pending</SelectItem>
          <SelectItem value="success">Approved</SelectItem>
          <SelectItem value="rejected">Rejected</SelectItem>
          <SelectItem value="all">All</SelectItem>
        </SelectContent>
      </Select>

      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm text-muted-foreground">
            {data?.meta ? `${data.meta.total} requests` : "Loading…"}
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="space-y-2 p-4">
              {Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-12 w-full" />)}
            </div>
          ) : withdrawals.length === 0 ? (
            <p className="p-6 text-center text-sm text-muted-foreground">No withdrawal requests.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b bg-muted/50 text-left text-xs text-muted-foreground">
                    <th className="px-4 py-2.5">Author</th>
                    <th className="px-4 py-2.5">Amount</th>
                    <th className="px-4 py-2.5">Bank</th>
                    <th className="px-4 py-2.5">Account</th>
                    <th className="px-4 py-2.5">Status</th>
                    <th className="px-4 py-2.5">Notes</th>
                    <th className="px-4 py-2.5">Date</th>
                    <th className="px-4 py-2.5">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {withdrawals.map((w) => (
                    <tr key={w.id} className="border-b last:border-0 hover:bg-muted/30">
                      <td className="px-4 py-3">
                        <p className="font-medium">{w.author_name}</p>
                        <p className="text-xs text-muted-foreground font-mono">#{w.user_id}</p>
                      </td>
                      <td className="px-4 py-3 font-bold">{formatIDR(w.amount_idr)}</td>
                      <td className="px-4 py-3">{w.bank_name}</td>
                      <td className="px-4 py-3">
                        <p className="font-mono">{w.account_number}</p>
                        <p className="text-xs text-muted-foreground">{w.account_name}</p>
                      </td>
                      <td className="px-4 py-3">
                        <Badge variant={statusVariant[w.status] ?? "outline"}>{w.status}</Badge>
                      </td>
                      <td className="px-4 py-3 text-xs text-muted-foreground max-w-[140px] truncate">
                        {w.notes ?? "—"}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground text-xs whitespace-nowrap">
                        {new Date(w.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3">
                        {w.status === "pending" && (
                          <Button
                            size="sm" variant="outline" className="gap-1.5"
                            onClick={() => { setProcessing(w); setAdminNote(""); }}
                          >
                            <CheckCircle size={13} /> Process
                          </Button>
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

      {/* Process Dialog */}
      <Dialog open={!!processing} onOpenChange={(o) => !o && setProcessing(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Process Withdrawal #{processing?.id}</DialogTitle>
          </DialogHeader>
          <div className="space-y-3 py-2">
            <p className="text-sm"><span className="text-muted-foreground">Author:</span> {processing?.author_name}</p>
            <p className="text-sm"><span className="text-muted-foreground">Amount:</span> {formatIDR(processing?.amount_idr ?? 0)}</p>
            <p className="text-sm"><span className="text-muted-foreground">Bank:</span> {processing?.bank_name} — {processing?.account_number}</p>
            <p className="text-sm"><span className="text-muted-foreground">Account Name:</span> {processing?.account_name}</p>
            <div className="space-y-1">
              <Label>Admin Note (optional)</Label>
              <Input
                placeholder="Transfer reference, rejection reason…"
                value={adminNote}
                onChange={(e) => setAdminNote(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button
              variant="outline"
              className="text-destructive hover:bg-destructive/10"
              disabled={processMut.isPending}
              onClick={() => processMut.mutate({ id: processing!.id, status: "rejected", note: adminNote })}
            >
              Reject
            </Button>
            <Button
              disabled={processMut.isPending}
              onClick={() => processMut.mutate({ id: processing!.id, status: "success", note: adminNote })}
            >
              Approve
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
