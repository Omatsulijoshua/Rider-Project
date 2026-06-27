"use client";

import { useState } from "react";
import Button from "@/components/ui/Button";
import { saveToken } from "@/lib/auth";
import { loginAdmin } from "./auth.api";

export default function Login({ onSuccess }: { onSuccess?: () => void }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("Access the administrative console.");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleLogin = async () => {
    try {
      setIsSubmitting(true);
      setError(null);
      const response = await loginAdmin({ email, password });
      saveToken(response.accessToken);
      setMessage("Authenticated. Establishing secure session...");
      setTimeout(() => {
        onSuccess?.();
      }, 800);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to authorize access.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <section className="card auth-card">
      <div className="section-heading">
        <h3 className="auth-title">Identify yourself</h3>
        <p className="auth-subtitle">{message}</p>
      </div>

      <div className="field-grid">
        <div className="input-group">
          <label>Admin Email</label>
          <input
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder="e.g. admin@rider.com"
            type="email"
            autoComplete="email"
          />
        </div>
        <div className="input-group">
          <label>Password</label>
          <input
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            placeholder="••••••••"
            type="password"
            autoComplete="current-password"
            onKeyDown={(e) => e.key === "Enter" && email && password && handleLogin()}
          />
        </div>
      </div>

      {error && <div className="auth-error">{error}</div>}

      <div className="inline-actions">
        <Button
          onClick={handleLogin}
          disabled={isSubmitting || !email || !password}
          className="login-submit"
        >
          {isSubmitting ? "Verifying..." : "Enter Console"}
        </Button>
      </div>

      <style jsx>{`
        .auth-card {
          border-radius: 24px;
        }
        .auth-title {
          font-family: Georgia, serif;
          font-size: 1.5rem;
          color: var(--text);
          margin-bottom: 0.25rem;
        }
        .auth-subtitle {
          color: var(--text-soft);
          font-size: 0.95rem;
        }
        .input-group {
          display: flex;
          flex-direction: column;
          gap: 0.5rem;
        }
        .input-group label {
          font-size: 0.85rem;
          font-weight: 600;
          color: var(--text-soft);
          padding-left: 0.25rem;
        }
        .auth-error {
          margin-top: 1rem;
          padding: 0.75rem;
          background: rgba(194, 65, 12, 0.08);
          border-radius: 12px;
          color: var(--danger);
          font-size: 0.9rem;
          text-align: center;
          border: 1px solid rgba(194, 65, 12, 0.2);
        }
      `}</style>
    </section>
  );
}
