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
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { Plus, StopCircle, Trophy } from "lucide-react";

interface Season {
  id: number; name: string; start_date: string; end_date: string;
  is_active: boolean; created_at: string;
}
interface LeaderRow { user_id: number; name: string; avatar_url: string | null; xp: number; rank: number; }

export default function SeasonsPage() {
  const qc = useQueryClient();
  const [creating, setCreating] = useState(false);
  const [viewSeason, setViewSeason] = useState<Season | null>(null);
  const [form, setForm] = useState({ name: "", start_date: "", end_date: "" });
  const [pendingEndId, setPendingEndId] = useState<number | null>(null);

  const seasonsQ = useQuery<{ data: Season[] }>({
    queryKey: ["admin-seasons"],
    queryFn: async () => {
      const { data } = await api.get("/admin/seasons?per_page=20");
      return data;
    },
  });

  const leaderQ = useQuery<{ data: LeaderRow[] }>({
    queryKey: ["season-leaderboard", viewSeason?.id],
    queryFn: async () => {
      const { data } = await api.get(`/admin/seasons/${viewSeason!.id}/leaderboard`);
      return data.data;
    },
    enabled: !!viewSeason,
  });

  const createMut = useMutation({
    mutationFn: () => api.post("/admin/seasons", form),
    onSuccess: () => {
      toast.success("Season created");
      qc.invalidateQueries({ queryKey: ["admin-seasons"] });
      setCreating(false);
      setForm({ name: "", start_date: "", end_date: "" });
    },
    onError: () => toast.error("Failed to create season"),
  });

  const endMut = useMutation({
    mutationFn: (id: number) => { setPendingEndId(id); return api.post(`/admin/seasons/${id}/end`); },
    onSuccess: () => {
      toast.success("Season ended");
      qc.invalidateQueries({ queryKey: ["admin-seasons"] });
      setPendingEndId(null);
    },
    onError: () => { toast.error("Failed to end season"); setPendingEndId(null); },
  });

  const seasons = seasonsQ.data?.data ?? [];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Season Management</h1>
        <Button onClick={() => setCreating(true)} className="gap-2">
          <Plus size={15} /> New Season
        </Button>
      </div>

      <div className="space-y-3">
        {seasonsQ.isLoading ? (
          Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-20 rounded-xl" />)
        ) : seasons.length === 0 ? (
          <p className="text-sm text-muted-foreground">No seasons yet.</p>
        ) : (
          seasons.map((s) => (
            <Card key={s.id} className={s.is_active ? "border-primary/50" : ""}>
              <CardContent className="flex items-center justify-between py-4">
                <div>
                  <div className="flex items-center gap-2">
                    <Trophy size={15} className={s.is_active ? "text-primary" : "text-muted-foreground"} />
                    <p className="font-semibold">{s.name}</p>
                    {s.is_active && <Badge>Active</Badge>}
                  </div>
                  <p className="text-xs text-muted-foreground mt-0.5">
                    {new Date(s.start_date).toLocaleDateString()} — {new Date(s.end_date).toLocaleDateString()}
                  </p>
                </div>
                <div className="flex gap-2">
                  <Button size="sm" variant="outline" onClick={() => setViewSeason(s)}>
                    Leaderboard
                  </Button>
                  {s.is_active && (
                    <Button
                      size="sm" variant="outline"
                      className="gap-1 text-destructive hover:bg-destructive/10 hover:text-destructive"
                      onClick={() => endMut.mutate(s.id)}
                      disabled={pendingEndId === s.id}
                    >
                      <StopCircle size={13} /> End
                    </Button>
                  )}
                </div>
              </CardContent>
            </Card>
          ))
        )}
      </div>

      {/* Create Season Dialog */}
      <Dialog open={creating} onOpenChange={setCreating}>
        <DialogContent>
          <DialogHeader><DialogTitle>Create New Season</DialogTitle></DialogHeader>
          <div className="space-y-3 py-2">
            <div className="space-y-1">
              <Label>Season Name</Label>
              <Input placeholder="e.g. Season 3 — Summer 2026"
                value={form.name} onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))} />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <Label>Start Date</Label>
                <Input type="date" value={form.start_date}
                  onChange={(e) => setForm((f) => ({ ...f, start_date: e.target.value }))} />
              </div>
              <div className="space-y-1">
                <Label>End Date</Label>
                <Input type="date" value={form.end_date}
                  onChange={(e) => setForm((f) => ({ ...f, end_date: e.target.value }))} />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="ghost" onClick={() => setCreating(false)}>Cancel</Button>
            <Button onClick={() => createMut.mutate()} disabled={createMut.isPending || !form.name || !form.start_date || !form.end_date}>
              {createMut.isPending ? "Creating…" : "Create Season"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Season Leaderboard Dialog */}
      <Dialog open={!!viewSeason} onOpenChange={(o) => !o && setViewSeason(null)}>
        <DialogContent className="max-w-md">
          <DialogHeader><DialogTitle>Leaderboard — {viewSeason?.name}</DialogTitle></DialogHeader>
          <div className="max-h-80 overflow-y-auto space-y-2">
            {leaderQ.isLoading ? (
              Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-8 w-full" />)
            ) : (leaderQ.data?.data ?? []).length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">No data yet.</p>
            ) : (
              (leaderQ.data?.data ?? []).map((row) => (
                <div key={row.user_id} className="flex items-center justify-between text-sm">
                  <div className="flex items-center gap-2">
                    <span className={`w-6 text-center font-bold text-xs ${row.rank <= 3 ? "text-yellow-500" : "text-muted-foreground"}`}>
                      #{row.rank}
                    </span>
                    <p className="font-medium">{row.name}</p>
                  </div>
                  <p className="font-mono font-bold">{row.xp.toLocaleString()} XP</p>
                </div>
              ))
            )}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
