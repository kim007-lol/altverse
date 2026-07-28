"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/lib/auth-store";
import {
  LayoutDashboard,
  Users,
  BookOpen,
  AlertCircle,
  Wallet,
  Settings,
  LogOut,
  TrendingUp,
  Trophy,
  Megaphone,
  ClipboardList,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";

const nav = [
  { href: "/dashboard",             label: "Dashboard",   icon: LayoutDashboard },
  { href: "/dashboard/users",       label: "Users",       icon: Users },
  { href: "/dashboard/content",     label: "Content",     icon: BookOpen },
  { href: "/dashboard/reports",     label: "Reports",     icon: AlertCircle },
  { href: "/dashboard/withdrawals", label: "Withdrawals", icon: Wallet },
  { href: "/dashboard/finance",     label: "Finance",     icon: TrendingUp },
  { href: "/dashboard/seasons",     label: "Seasons",     icon: Trophy },
  { href: "/dashboard/broadcast",   label: "Broadcast",   icon: Megaphone },
  { href: "/dashboard/audit",       label: "Audit Log",   icon: ClipboardList },
  { href: "/dashboard/settings",    label: "Settings",    icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, clearAuth } = useAuthStore();

  function handleLogout() {
    clearAuth();
    toast.success("Logged out");
    router.push("/login");
  }

  return (
    <aside className="flex h-screen w-60 flex-col border-r bg-card">
      {/* Brand */}
      <div className="flex h-16 items-center gap-2 border-b px-5">
        <span className="text-xl">📚</span>
        <span className="font-bold text-lg leading-tight">AU Reader<br />
          <span className="text-xs font-normal text-muted-foreground">Admin Panel</span>
        </span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 space-y-0.5 overflow-y-auto px-3 py-4">
        {nav.map(({ href, label, icon: Icon }) => (
          <Link
            key={href}
            href={href}
            className={cn(
              "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
              pathname === href
                ? "bg-primary text-primary-foreground"
                : "text-muted-foreground hover:bg-accent hover:text-foreground"
            )}
          >
            <Icon size={16} />
            {label}
          </Link>
        ))}
      </nav>

      {/* User + Logout */}
      <div className="border-t px-4 py-3">
        <p className="truncate text-xs font-medium">{user?.name}</p>
        <p className="truncate text-xs text-muted-foreground">{user?.email}</p>
        <Button
          variant="ghost"
          size="sm"
          className="mt-2 w-full justify-start gap-2 text-destructive hover:bg-destructive/10 hover:text-destructive"
          onClick={handleLogout}
        >
          <LogOut size={14} />
          Logout
        </Button>
      </div>
    </aside>
  );
}
