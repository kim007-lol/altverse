import { create } from "zustand";

interface AdminUser {
  id: number;
  name: string;
  email: string;
  role: string;
}

interface AuthState {
  user: AdminUser | null;
  token: string | null;
  setAuth: (user: AdminUser, token: string) => void;
  clearAuth: () => void;
  isAdmin: () => boolean;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  token: null,

  setAuth: (user, token) => {
    localStorage.setItem("admin_token", token);
    localStorage.setItem("admin_user", JSON.stringify(user));
    set({ user, token });
  },

  clearAuth: () => {
    localStorage.removeItem("admin_token");
    localStorage.removeItem("admin_user");
    set({ user: null, token: null });
  },

  isAdmin: () => get().user?.role === "admin",
}));

// Rehydrate from localStorage on first load (client only).
export function rehydrateAuth() {
  if (typeof window === "undefined") return;
  const token = localStorage.getItem("admin_token");
  const raw = localStorage.getItem("admin_user");
  if (token && raw) {
    try {
      const user = JSON.parse(raw) as AdminUser;
      useAuthStore.setState({ user, token });
    } catch {
      // stale data — ignore
    }
  }
}
