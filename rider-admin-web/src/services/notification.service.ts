export type AdminNotification = {
  id: string;
  title: string;
  detail: string;
  severity: "info" | "warning" | "critical";
};

export const notificationService = {
  list(): AdminNotification[] {
    return [
      {
        id: "notif-1",
        title: "Settlement batch delayed",
        detail: "Two bank partners are processing slower than usual.",
        severity: "warning",
      },
      {
        id: "notif-2",
        title: "Fraud rule auto-paused 8 riders",
        detail: "Velocity checks flagged 8 duplicate wallets in the last hour.",
        severity: "critical",
      },
    ];
  },
};
