export default function Loader({ label = "Loading module" }: { label?: string }) {
  return (
    <div className="loader">
      <span className="loader__dot" />
      <span>{label}</span>
    </div>
  );
}
