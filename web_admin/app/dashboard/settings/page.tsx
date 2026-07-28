"use client";

import { useEffect, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Save } from "lucide-react";

interface Settings {
  min_withdrawal_idr: number;
  platform_fee_percent: number;
  max_tips_per_day: number;
  coin_to_idr_rate: number;
  maintenance_mode: boolean;
}

export default function SettingsPage() {
  const qc = useQueryClient();
  const [form, setForm] = useState<Settings | null>(null);

  const { data, isLoading } = useQuery<Settings>({
    queryKey: ["admin-settings"],
    queryFn: async () => {
      const { data } = await api.get("/admin/settings");
      return data.data;
    },
  });

  useEffect(() => {
    if (data) setForm(data);
  }, [data]);

  const saveMut = useMutation({
    mutationFn: (settings: Settings) => api.put("/admin/settings", { settings }),
    onSuccess: () => {
      toast.success("Settings saved");
      qc.invalidateQueries({ queryKey: ["admin-settings"] });
    },
    onError: () => toast.error("Failed to save settings"),
  });

  function setField<K extends keyof Settings>(key: K, value: Settings[K]) {
    setForm((prev) => prev ? { ...prev, [key]: value } : prev);
  }

  if (isLoading || !form) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold">Platform Settings</h1>
        <Skeleton className="h-80 w-full max-w-lg rounded-xl" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Platform Settings</h1>

      <Card className="max-w-lg">
        <CardHeader><CardTitle className="text-base">Finance</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-1">
            <Label>Minimum Withdrawal (IDR)</Label>
            <Input
              type="number" min={0}
              value={form.min_withdrawal_idr}
              onChange={(e) => setField("min_withdrawal_idr", Number(e.target.value))}
            />
          </div>
          <div className="space-y-1">
            <Label>Platform Fee (%)</Label>
            <Input
              type="number" min={0} max={100} step={0.5}
              value={form.platform_fee_percent}
              onChange={(e) => setField("platform_fee_percent", Number(e.target.value))}
            />
          </div>
          <div className="space-y-1">
            <Label>Coin → IDR Rate</Label>
            <Input
              type="number" min={0}
              value={form.coin_to_idr_rate}
              onChange={(e) => setField("coin_to_idr_rate", Number(e.target.value))}
            />
            <p className="text-xs text-muted-foreground">1 coin = {form.coin_to_idr_rate} IDR</p>
          </div>
        </CardContent>
      </Card>

      <Card className="max-w-lg">
        <CardHeader><CardTitle className="text-base">Platform Rules</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-1">
            <Label>Max Tips Per Day (per user)</Label>
            <Input
              type="number" min={1}
              value={form.max_tips_per_day}
              onChange={(e) => setField("max_tips_per_day", Number(e.target.value))}
            />
          </div>
          <div className="flex items-center gap-3">
            <input
              id="maintenance"
              type="checkbox"
              className="h-4 w-4 rounded border"
              checked={form.maintenance_mode}
              onChange={(e) => setField("maintenance_mode", e.target.checked)}
            />
            <Label htmlFor="maintenance" className="cursor-pointer">
              Maintenance Mode
              <span className="ml-2 text-xs text-muted-foreground">(shows maintenance banner to users)</span>
            </Label>
          </div>
        </CardContent>
      </Card>

      <Button
        onClick={() => saveMut.mutate(form)}
        disabled={saveMut.isPending}
        className="gap-2"
      >
        <Save size={15} />
        {saveMut.isPending ? "Saving…" : "Save Settings"}
      </Button>
    </div>
  );
}
