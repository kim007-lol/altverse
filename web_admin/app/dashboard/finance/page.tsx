"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { TrendingUp, TrendingDown, DollarSign, Users } from "lucide-react";

interface Overview {
  period: string;
  total_revenue: number;
  total_topups: number;
  total_withdrawn: number;
  pending_withdraw: number;
  net_retained: number;
  daily_revenue: { day: string; revenue: number; count: number }[];
}

interface AuthorRow {
  author_id: number; name: string; pen_name: string | null;
  avatar_url: string | null; author_tier: string;
  total_earned: number; total_idr: number;
}

interface SpenderRow {
  user_id: number; name: string; avatar_url: string | null; coins_spent: number;
}

function formatIDR(n: number) {
  return new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", maximumFractionDigits: 0 }).format(n);
}

function KpiCard({ label, value, icon: Icon, sub, positive }: {
  label: string; value: string; icon: React.ElementType; sub?: string; positive?: boolean;
}) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{label}</CardTitle>
        <Icon size={16} className="text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <p className={`text-xl font-bold ${positive === false ? "text-destructive" : ""}`}>{value}</p>
        {sub && <p className="text-xs text-muted-foreground mt-0.5">{sub}</p>}
      </CardContent>
    </Card>
  );
}

export default function FinancePage() {
  const [period, setPeriod] = useState("30d");

  const overviewQ = useQuery<Overview>({
    queryKey: ["finance-overview", period],
    queryFn: async () => {
      const { data } = await api.get(`/admin/finance?period=${period}`);
      return data.data;
    },
  });

  const earningsQ = useQuery<{ data: AuthorRow[] }>({
    queryKey: ["finance-authors"],
    queryFn: async () => {
      const { data } = await api.get("/admin/finance/author-earnings?per_page=10");
      return data;
    },
  });

  const spendersQ = useQuery<{ data: SpenderRow[] }>({
    queryKey: ["finance-spenders"],
    queryFn: async () => {
      const { data } = await api.get("/admin/finance/top-spenders");
      return data.data;
    },
  });

  const ov = overviewQ.data;
  const maxRevenue = Math.max(...(ov?.daily_revenue?.map((d) => d.revenue) ?? [1]));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Finance Overview</h1>
        <Select value={period} onValueChange={(v) => { if (v) setPeriod(v); }}>
          <SelectTrigger className="w-32"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="7d">Last 7 days</SelectItem>
            <SelectItem value="30d">Last 30 days</SelectItem>
            <SelectItem value="90d">Last 90 days</SelectItem>
            <SelectItem value="all">All time</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* KPIs */}
      {overviewQ.isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-24 rounded-xl" />)}
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <KpiCard label="Total Revenue" value={formatIDR(ov?.total_revenue ?? 0)} icon={DollarSign} sub={`${ov?.total_topups ?? 0} transactions`} />
          <KpiCard label="Total Withdrawn" value={formatIDR(ov?.total_withdrawn ?? 0)} icon={TrendingDown} positive={false} />
          <KpiCard label="Net Retained" value={formatIDR(ov?.net_retained ?? 0)} icon={TrendingUp} />
          <KpiCard label="Pending Withdrawal" value={formatIDR(ov?.pending_withdraw ?? 0)} icon={DollarSign} sub="Awaiting approval" />
        </div>
      )}

      {/* Revenue chart (bar) */}
      <Card>
        <CardHeader><CardTitle className="text-base">Daily Revenue</CardTitle></CardHeader>
        <CardContent>
          {ov?.daily_revenue?.length ? (
            <div className="flex items-end gap-1 h-32 overflow-x-auto">
              {ov.daily_revenue.map((d) => (
                <div key={d.day} className="flex flex-col items-center gap-1 min-w-[28px]" title={`${d.day}: ${formatIDR(d.revenue)}`}>
                  <div
                    className="w-5 rounded-t bg-primary transition-all"
                    style={{ height: Math.max(4, (d.revenue / maxRevenue) * 96) }}
                  />
                  <span className="text-[9px] text-muted-foreground -rotate-45 origin-top-left">{d.day.slice(5)}</span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">No revenue data for this period.</p>
          )}
        </CardContent>
      </Card>

      <div className="grid gap-4 lg:grid-cols-2">
        {/* Top author earners */}
        <Card>
          <CardHeader><CardTitle className="text-base">Top Author Earners</CardTitle></CardHeader>
          <CardContent className="space-y-2">
            {earningsQ.isLoading ? (
              Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-8 w-full" />)
            ) : (
              earningsQ.data?.data?.map((a, i) => (
                <div key={a.author_id} className="flex items-center justify-between text-sm">
                  <div className="flex items-center gap-2">
                    <span className="w-5 text-center text-muted-foreground font-mono text-xs">{i + 1}</span>
                    <div>
                      <p className="font-medium">{a.pen_name ?? a.name}</p>
                      <Badge variant="outline" className="text-[10px] capitalize">{a.author_tier}</Badge>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="font-bold">{a.total_earned.toLocaleString()} coins</p>
                    <p className="text-xs text-muted-foreground">{formatIDR(a.total_idr)}</p>
                  </div>
                </div>
              ))
            )}
          </CardContent>
        </Card>

        {/* Top spenders */}
        <Card>
          <CardHeader><CardTitle className="text-base flex items-center gap-2"><Users size={15} /> Top Spenders</CardTitle></CardHeader>
          <CardContent className="space-y-2">
            {spendersQ.isLoading ? (
              Array.from({ length: 5 }).map((_, i) => <Skeleton key={i} className="h-8 w-full" />)
            ) : (
              (spendersQ.data?.data ?? []).map((s: SpenderRow, i: number) => (
                <div key={s.user_id} className="flex items-center justify-between text-sm">
                  <div className="flex items-center gap-2">
                    <span className="w-5 text-center text-muted-foreground font-mono text-xs">{i + 1}</span>
                    <p className="font-medium">{s.name}</p>
                  </div>
                  <p className="font-bold">{s.coins_spent.toLocaleString()} coins</p>
                </div>
              ))
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
