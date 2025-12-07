export const API_BASE_URL = import.meta.env.VITE_API_URL || "/api/v1";

const getWebSocketUrl = () => {
  if (import.meta.env.VITE_WS_URL) return import.meta.env.VITE_WS_URL;
  const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
  return `${protocol}//${window.location.host}/api/v1`;
};

export const WS_BASE_URL = getWebSocketUrl();
