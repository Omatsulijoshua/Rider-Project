"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Login from "@/features/auth/Login";
import { isAuthenticated } from "@/lib/auth";

export default function LoginPage() {
  const router = useRouter();
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    setIsMounted(true);
    if (isAuthenticated()) {
      router.push("/");
    }
  }, [router]);

  if (!isMounted) return null;

  return (
    <main className="login-page">
      <div className="login-container">
        <div className="login-branding">
          <div className="brand__mark">R</div>
          <div className="brand__info">
            <p className="brand__eyebrow">Platform Admin</p>
            <h1 className="login-title">Rider Console</h1>
          </div>
        </div>
        
        <Login onSuccess={() => router.push("/")} />
        
        <div className="login-footer">
          <p className="muted-copy">&copy; 2026 Rider Logistics. All systems operational.</p>
        </div>
      </div>

      <style jsx>{`
        .login-page {
          min-height: 100vh;
          display: grid;
          place-items: center;
          padding: 2rem;
          background: 
            radial-gradient(circle at 10% 20%, rgba(239, 108, 0, 0.1), transparent 40%),
            radial-gradient(circle at 90% 80%, rgba(15, 118, 110, 0.1), transparent 40%),
            linear-gradient(135deg, #fdf8f3 0%, #f7efe5 100%);
        }

        .login-container {
          width: 100%;
          max-width: 440px;
          display: flex;
          flex-direction: column;
          gap: 2.5rem;
          animation: fadeIn 0.8s ease-out;
        }

        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(10px); }
          to { opacity: 1; transform: translateY(0); }
        }

        .login-branding {
          display: flex;
          align-items: center;
          gap: 1.2rem;
          justify-content: center;
        }

        .brand__info {
          display: flex;
          flex-direction: column;
        }

        .login-title {
          font-family: Georgia, serif;
          font-size: 2rem;
          margin: 0;
          color: var(--text);
        }

        .login-footer {
          text-align: center;
          margin-top: 1rem;
        }

        :global(.auth-card) {
          background: rgba(255, 251, 246, 0.9) !important;
          backdrop-filter: blur(20px) !important;
          border: 1px solid rgba(92, 63, 43, 0.15) !important;
          padding: 2.5rem !important;
          box-shadow: 0 30px 60px rgba(63, 37, 19, 0.15) !important;
        }

        :global(.field-grid input) {
          background: white !important;
          padding: 1.1rem 1.25rem !important;
          font-size: 1rem !important;
          transition: border-color 0.2s ease, box-shadow 0.2s ease !important;
        }

        :global(.field-grid input:focus) {
          outline: none !important;
          border-color: var(--primary) !important;
          box-shadow: 0 0 0 4px rgba(239, 108, 0, 0.1) !important;
        }

        :global(.inline-actions) {
          margin-top: 1.5rem !important;
          flex-direction: column !important;
          align-items: stretch !important;
          gap: 1.2rem !important;
        }

        :global(.inline-actions button) {
          width: 100% !important;
          padding: 1.1rem !important;
          font-size: 1.1rem !important;
        }

        :global(.inline-actions .muted-copy) {
          text-align: center !important;
        }
      `}</style>
    </main>
  );
}
