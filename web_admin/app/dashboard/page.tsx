"use client";

import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Users, BookOpen, TrendingUp, Wallet, AlertCircle, Clock } from "lucide-react";

interface Overview {
  total_users: number;
  total_authors: number;
  total_series: number;
  total_episodes: number;
  total_revenue_idr: number;
  pending_withdrawals: number;
  pending_reports: number;
  user_growth: { day: string; count: number }[];
  recent_topups: { order_id: string; amount_idr: number; coins: number; status: string; created_at: string }[];
}

function StatCard({ title, value, icon: Icon, sub, alert }: {
  title: string; value: string | number; icon: React.ElementType; sub?: string; alert?: boolean;
}) {
  return (
    <Card className={alert && Number(value) > 0 ? "border-destructive/50" : ""}>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        <Icon size={16} className={alert && Number(value) > 0 ? "text-destructive" : "text-muted-foreground"} />
      </CardHeader>
      <CardContent>
        <p className={`text-2xl font-bold ${alert && Number(value) > 0 ? "text-destructive" : ""}`}>{value}</p>
        {sub && <p className="text-xs text-muted-foreground mt-0.5">{sub}</p>}
      </CardContent>
    </Card>
  );
}

function formatIDR(n: number) {
  return new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", maximumFractionDigits: 0 }).format(n);
}

export default function DashboardPage() {
  const { data, isLoading } = useQuery<Overview>({
    queryKey: ["admin-overview"],
    queryFn: async () => {
      const { data } = await api.get("/admin/dashboard");
      return data.data;
    },
  });

  if (isLoading) {
    return (
      <div className="space-y-6">
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 7 }).map((_, i) => (
            <Skeleton key={i} className="h-28 rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Dashboard</h1>

      {/* KPI cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard title="Total Users" value={data?.total_users ?? 0} icon={Users} />
        <StatCard title="Total Authors" value={data?.total_authors ?? 0} icon={Users} sub="Active creators" />
        <StatCard title="Series" value={data?.total_series ?? 0} icon={BookOpen} />
        <StatCard title="Episodes" value={data?.total_episodes ?? 0} icon={BookOpen} />
        <StatCard title="Total Revenue" value={formatIDR(data?.total_revenue_idr ?? 0)} icon={Wallet} sub="All-time top-ups" />
        <StatCard title="Pending Withdrawals" value={data?.pending_withdrawals ?? 0} icon={Clock} alert />
        <StatCard title="Pending Reports" value={data?.pending_reports ?? 0} icon={AlertCircle} alert />
      </div>

      {/* User growth + Recent topups */}
      <div className="grid gap-4 lg:grid-cols-2">
        {/* User growth table */}
        <Card>
          <CardHeader><CardTitle className="text-base">User Growth (Last 7 Days)</CardTitle></CardHeader>
          <CardContent>
            {data?.user_growth?.length ? (
              <div className="space-y-2">
                {data.user_growth.map((row, i) => (
                  <div key={row.day || String(i)} className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">{row.day}</span>
                    <div className="flex items-center gap-2">
                      <div className="h-1.5 rounded-full bg-primary" style={{ width: Math.max(4, row.count * 8) }} />
                      <span className="font-medium">{row.count}</span>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No data yet.</p>
            )}
          </CardContent>
        </Card>

        {/* Recent top-ups */}
        <Card>
          <CardHeader><CardTitle className="text-base">Recent Top-ups</CardTitle></CardHeader>
          <CardContent>
            <div className="space-y-2">
              {data?.recent_topups?.map((tx) => (
                <div key={tx.order_id} className="flex items-center justify-between text-sm">
                  <div>
                    <p className="font-medium truncate max-w-[160px]">{tx.order_id}</p>
                    <p className="text-xs text-muted-foreground">{tx.coins} coins</p>
                  </div>
                  <div className="text-right">
                    <p className="font-medium">{formatIDR(tx.amount_idr)}</p>
                    <Badge variant={tx.status === "success" ? "default" : "secondary"} className="text-xs">
                      {tx.status}
                    </Badge>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
