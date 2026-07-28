"use client";

import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Megaphone, Send } from "lucide-react";

const TEMPLATES = [
  { label: "Maintenance Notice", title: "🔧 Scheduled Maintenance", body: "We will be performing maintenance on {DATE}. The app may be temporarily unavailable." },
  { label: "New Feature", title: "✨ New Feature Available", body: "We've just shipped something new! Open the app to check it out." },
  { label: "Season Start", title: "🏆 New Season Has Started!", body: "A new season has begun. Earn XP, support your favorite authors, and climb the leaderboard!" },
  { label: "Season End", title: "🎉 Season Has Ended!", body: "The season is over. Check the leaderboard to see the final rankings and your rewards." },
];

export default function BroadcastPage() {
  const [form, setForm] = useState({ title: "", body: "", type: "announcement", target: "all" });
  const [sent, setSent] = useState<{ queued: number; target: string } | null>(null);

  const sendMut = useMutation({
    mutationFn: () => api.post("/admin/broadcast", form),
    onSuccess: ({ data }) => {
      toast.success(`Broadcast queued for ${data.data.queued} users`);
      setSent(data.data);
      setForm((f) => ({ ...f, title: "", body: "" }));
    },
    onError: () => toast.error("Failed to send broadcast"),
  });

  function applyTemplate(t: typeof TEMPLATES[0]) {
    setForm((f) => ({ ...f, title: t.title, body: t.body }));
  }

  const charCount = form.body.length;

  return (
    <div className="space-y-6 max-w-2xl">
      <h1 className="text-2xl font-bold">Broadcast Notification</h1>

      {/* Templates */}
      <Card>
        <CardHeader><CardTitle className="text-sm text-muted-foreground">Quick Templates</CardTitle></CardHeader>
        <CardContent className="flex flex-wrap gap-2">
          {TEMPLATES.map((t) => (
            <Button key={t.label} variant="outline" size="sm" onClick={() => applyTemplate(t)}>
              {t.label}
            </Button>
          ))}
        </CardContent>
      </Card>

      {/* Compose */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Megaphone size={16} /> Compose Message
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <Label>Target Audience</Label>
              <Select value={form.target} onValueChange={(v) => { if (v) setForm((f) => ({ ...f, target: v })); }}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Users</SelectItem>
                  <SelectItem value="reader">Readers Only</SelectItem>
                  <SelectItem value="author">Authors Only</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1">
              <Label>Notification Type</Label>
              <Select value={form.type} onValueChange={(v) => { if (v) setForm((f) => ({ ...f, type: v })); }}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="announcement">Announcement</SelectItem>
                  <SelectItem value="maintenance">Maintenance</SelectItem>
                  <SelectItem value="season_event">Season Event</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-1">
            <Label>Title</Label>
            <Input
              placeholder="Notification title…"
              value={form.title}
              onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
              maxLength={100}
            />
          </div>

          <div className="space-y-1">
            <Label>Message Body</Label>
            <textarea
              className="w-full rounded-md border bg-transparent px-3 py-2 text-sm shadow-xs placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring resize-none"
              rows={4}
              placeholder="Write your message here…"
              value={form.body}
              onChange={(e) => setForm((f) => ({ ...f, body: e.target.value }))}
              maxLength={500}
            />
            <p className="text-xs text-muted-foreground text-right">{charCount}/500</p>
          </div>

          <div className="flex items-center justify-between">
            <div className="text-sm text-muted-foreground">
              Sending to: <Badge variant="outline" className="ml-1 capitalize">{form.target}</Badge>
            </div>
            <Button
              onClick={() => sendMut.mutate()}
              disabled={sendMut.isPending || !form.title || !form.body}
              className="gap-2"
            >
              <Send size={14} />
              {sendMut.isPending ? "Sending…" : "Send Broadcast"}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Last sent */}
      {sent && (
        <Card className="border-green-500/30 bg-green-50 dark:bg-green-950/20">
          <CardContent className="py-3 text-sm text-green-700 dark:text-green-400">
            ✓ Last broadcast queued for <strong>{sent.queued}</strong> {sent.target} users.
          </CardContent>
        </Card>
      )}
    </div>
  );
}
