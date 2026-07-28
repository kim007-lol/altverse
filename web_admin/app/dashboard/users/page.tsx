"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Search, ShieldOff, ShieldCheck, Coins } from "lucide-react";

interface User {
  id: number; name: string; email: string; role: string;
  avatar_url: string | null; coins: number; level: number;
  status: "active" | "banned"; created_at: string;
}

interface CoinTx {
  id: number; type: string; coins: number; notes: string; created_at: string;
}

interface PageMeta { total: number; page: number; per_page: number; last_page: number; }

function CoinDialog({ user, onClose }: { user: User; onClose: () => void }) {
  const qc = useQueryClient();
  const [amount, setAmount] = useState("");
  const [reason, setReason] = useState("");

  const historyQ = useQuery<{ data: CoinTx[] }>({
    queryKey: ["user-coins-history", user.id],
    queryFn: async () => {
      const { data } = await api.get(`/admin/users/${user.id}/coins/history`);
      return data.data;
    },
  });

  const adjustMut = useMutation({
    mutationFn: () => api.post(`/admin/users/${user.id}/coins`, {
      amount: parseInt(amount, 10),
      reason,
    }),
    onSuccess: () => {
      toast.success(`Coins adjusted for ${user.name}`);
      qc.invalidateQueries({ queryKey: ["admin-users"] });
      qc.invalidateQueries({ queryKey: ["user-coins-history", user.id] });
      setAmount("");
      setReason("");
    },
    onError: () => toast.error("Failed to adjust coins"),
  });

  const parsed = parseInt(amount, 10);
  const isValid = !isNaN(parsed) && parsed !== 0 && reason.trim().length > 0;

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Coin Management — {user.name}</DialogTitle>
        </DialogHeader>

        <div className="text-center py-2">
          <p className="text-3xl font-bold font-mono">{user.coins.toLocaleString()}</p>
          <p className="text-xs text-muted-foreground mt-0.5">current balance</p>
        </div>

        {/* Adjust form */}
        <div className="space-y-3 border rounded-lg p-3">
          <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">Adjust Coins</p>
          <div className="space-y-1">
            <Label className="text-xs">Amount (positive = add, negative = deduct)</Label>
            <Input
              type="number"
              placeholder="e.g. 100 or -50"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />
          </div>
          <div className="space-y-1">
            <Label className="text-xs">Reason</Label>
            <Input
              placeholder="Reason for adjustment…"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
            />
          </div>
          <Button
            className="w-full gap-2"
            onClick={() => adjustMut.mutate()}
            disabled={adjustMut.isPending || !isValid}
          >
            <Coins size={14} />
            {adjustMut.isPending ? "Adjusting…" : parsed > 0 ? `Add ${parsed} coins` : parsed < 0 ? `Deduct ${Math.abs(parsed)} coins` : "Adjust"}
          </Button>
        </div>

        {/* History */}
        <div className="space-y-2">
          <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">Recent Transactions</p>
          <div className="max-h-52 overflow-y-auto space-y-1">
            {historyQ.isLoading ? (
              Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-8 w-full" />)
            ) : (historyQ.data?.data ?? []).length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-2">No transactions yet.</p>
            ) : (
              (historyQ.data?.data ?? []).map((tx) => (
                <div key={tx.id} className="flex items-center justify-between text-xs rounded bg-muted/40 px-2.5 py-1.5">
                  <div>
                    <p className="font-medium text-sm">{tx.notes || tx.type}</p>
                    <p className="text-muted-foreground">{new Date(tx.created_at).toLocaleString()}</p>
                  </div>
                  <span className={`font-mono font-bold ${tx.coins >= 0 ? "text-green-600" : "text-destructive"}`}>
                    {tx.coins >= 0 ? "+" : ""}{tx.coins}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>

        <DialogFooter>
          <Button variant="ghost" onClick={onClose}>Close</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export default function UsersPage() {
  const qc = useQueryClient();
  const [search, setSearch] = useState("");
  const [role, setRole] = useState("all");
  const [page, setPage] = useState(1);
  const [coinUser, setCoinUser] = useState<User | null>(null);
  const [pendingStatusId, setPendingStatusId] = useState<number | null>(null);

  const { data, isLoading } = useQuery<{ data: User[]; meta: PageMeta }>({
    queryKey: ["admin-users", search, role, page],
    queryFn: async () => {
      const params = new URLSearchParams({ page: String(page), per_page: "20" });
      if (search) params.set("search", search);
      if (role !== "all") params.set("role", role);
      const { data } = await api.get(`/admin/users?${params}`);
      return data;
    },
  });

  const statusMut = useMutation({
    mutationFn: ({ id, status }: { id: number; status: string }) => {
      setPendingStatusId(id);
      return api.post(`/admin/users/${id}/status`, { status });
    },
    onSuccess: () => {
      toast.success("User status updated");
      qc.invalidateQueries({ queryKey: ["admin-users"] });
      setPendingStatusId(null);
    },
    onError: () => {
      toast.error("Failed to update status");
      setPendingStatusId(null);
    },
  });

  const users = data?.data ?? [];
  const meta = data?.meta;

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">User Management</h1>

      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-48">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search name or email…"
            className="pl-8"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
          />
        </div>
        <Select value={role} onValueChange={(v) => { if (v) { setRole(v); setPage(1); } }}>
          <SelectTrigger className="w-36">
            <SelectValue placeholder="Role" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Roles</SelectItem>
            <SelectItem value="reader">Reader</SelectItem>
            <SelectItem value="author">Author</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm text-muted-foreground">
            {meta ? `${meta.total} users total` : "Loading…"}
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="space-y-2 p-4">
              {Array.from({ length: 8 }).map((_, i) => <Skeleton key={i} className="h-10 w-full" />)}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b bg-muted/50 text-left text-xs text-muted-foreground">
                    <th className="px-4 py-2.5">User</th>
                    <th className="px-4 py-2.5">Role</th>
                    <th className="px-4 py-2.5">Coins</th>
                    <th className="px-4 py-2.5">Level</th>
                    <th className="px-4 py-2.5">Status</th>
                    <th className="px-4 py-2.5">Joined</th>
                    <th className="px-4 py-2.5">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((u) => (
                    <tr key={u.id} className="border-b last:border-0 hover:bg-muted/30">
                      <td className="px-4 py-3">
                        <p className="font-medium">{u.name}</p>
                        <p className="text-xs text-muted-foreground">{u.email}</p>
                      </td>
                      <td className="px-4 py-3">
                        <Badge variant="outline" className="capitalize">{u.role}</Badge>
                      </td>
                      <td className="px-4 py-3 font-mono">{u.coins.toLocaleString()}</td>
                      <td className="px-4 py-3">{u.level}</td>
                      <td className="px-4 py-3">
                        <Badge variant={u.status === "active" ? "default" : "destructive"}>
                          {u.status}
                        </Badge>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {new Date(u.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-1.5">
                          <Button
                            size="sm" variant="outline" className="gap-1 text-xs"
                            onClick={() => setCoinUser(u)}
                          >
                            <Coins size={12} /> Coins
                          </Button>
                          {u.status === "active" ? (
                            <Button
                              size="sm" variant="outline"
                              className="gap-1 text-xs text-destructive hover:bg-destructive/10 hover:text-destructive"
                              onClick={() => statusMut.mutate({ id: u.id, status: "banned" })}
                              disabled={pendingStatusId === u.id}
                            >
                              <ShieldOff size={12} /> Ban
                            </Button>
                          ) : (
                            <Button
                              size="sm" variant="outline" className="gap-1 text-xs"
                              onClick={() => statusMut.mutate({ id: u.id, status: "active" })}
                              disabled={pendingStatusId === u.id}
                            >
                              <ShieldCheck size={12} /> Restore
                            </Button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Pagination */}
      {meta && meta.last_page > 1 && (
        <div className="flex items-center justify-between text-sm">
          <span className="text-muted-foreground">Page {meta.page} of {meta.last_page}</span>
          <div className="flex gap-2">
            <Button size="sm" variant="outline" onClick={() => setPage((p) => p - 1)} disabled={page === 1}>Previous</Button>
            <Button size="sm" variant="outline" onClick={() => setPage((p) => p + 1)} disabled={page === meta.last_page}>Next</Button>
          </div>
        </div>
      )}

      {coinUser && <CoinDialog user={coinUser} onClose={() => setCoinUser(null)} />}
    </div>
  );
}
