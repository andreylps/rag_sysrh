import React, { useState, useEffect } from "react";
import {
  RefreshCw,
  Activity,
  Server,
  Database,
  Github,
  Cpu,
} from "lucide-react";
import HealthStatusCard from "../components/HealthStatusCard";
import { API_BASE_URL } from "../config";

const AdminDashboard = () => {
  const [healthData, setHealthData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);

  const fetchHealthData = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`${API_BASE_URL}/admin/health`);
      if (!response.ok) {
        throw new Error("Falha ao buscar dados de saúde do sistema");
      }
      const data = await response.json();
      setHealthData(data);
      setLastUpdated(new Date());
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHealthData();
  }, []);

  const getServiceIcon = (serviceName) => {
    const name = serviceName.toLowerCase();
    if (name.includes("neo4j")) return <Database size={20} />;
    if (name.includes("github")) return <Github size={20} />;
    if (name.includes("openai") || name.includes("llm"))
      return <Cpu size={20} />;
    return <Server size={20} />;
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-8">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-3xl font-bold text-white flex items-center gap-3">
            <Activity className="text-blue-500" />
            Painel do Maestro
          </h1>
          <p className="text-gray-400 mt-1">
            Monitoramento em tempo real da saúde do sistema e serviços
            conectados
          </p>
        </div>

        <button
          onClick={fetchHealthData}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <RefreshCw size={18} className={loading ? "animate-spin" : ""} />
          {loading ? "Atualizando..." : "Atualizar Status"}
        </button>
      </div>

      {/* Global Status Banner */}
      {healthData && (
        <div
          className={`p-4 rounded-xl border ${
            healthData.status === "healthy"
              ? "bg-green-500/10 border-green-500/20"
              : "bg-red-500/10 border-red-500/20"
          } mb-8`}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div
                className={`w-3 h-3 rounded-full ${
                  healthData.status === "healthy"
                    ? "bg-green-500"
                    : "bg-red-500"
                } animate-pulse`}
              />
              <span className="text-lg font-semibold text-white">
                Status Global do Sistema:{" "}
                <span
                  className={
                    healthData.status === "healthy"
                      ? "text-green-400"
                      : "text-red-400"
                  }
                >
                  {healthData.status === "healthy"
                    ? "OPERACIONAL"
                    : "DEGRADADO"}
                </span>
              </span>
            </div>
            {lastUpdated && (
              <span className="text-xs text-gray-500">
                Última atualização: {lastUpdated.toLocaleTimeString()}
              </span>
            )}
          </div>
        </div>
      )}

      {/* Error State */}
      {error && (
        <div className="p-4 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 mb-6">
          <p className="font-medium">Erro ao carregar dashboard:</p>
          <p className="text-sm opacity-80">{error}</p>
        </div>
      )}

      {/* Services Grid */}
      {healthData && healthData.components && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {Object.entries(healthData.components).map(([key, component]) => (
            <HealthStatusCard
              key={key}
              service={key.charAt(0).toUpperCase() + key.slice(1)} // Capitalize
              status={component.status === "up" ? "ok" : "error"}
              details={component.details || component.error}
            />
          ))}
        </div>
      )}

      {!loading && !error && !healthData && (
        <div className="text-center py-12 text-gray-500">
          Nenhum dado de saúde disponível.
        </div>
      )}
    </div>
  );
};

export default AdminDashboard;
