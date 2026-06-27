"use client";

import type { ReactNode } from "react";

export default function Modal({
  title,
  children,
}: {
  title: string;
  children: ReactNode;
}) {
  return (
    <div className="modal">
      <div className="modal__panel">
        <div className="section-heading">
          <h3>{title}</h3>
        </div>
        {children}
      </div>
    </div>
  );
}
