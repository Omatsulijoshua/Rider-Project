"use client";

import Button from "./Button";
import Modal from "./Modal";

export default function ConfirmDialog({
  title,
  message,
}: {
  title: string;
  message: string;
}) {
  return (
    <Modal title={title}>
      <p className="muted-copy">{message}</p>
      <div className="inline-actions">
        <Button variant="secondary">Cancel</Button>
        <Button>Confirm</Button>
      </div>
    </Modal>
  );
}
