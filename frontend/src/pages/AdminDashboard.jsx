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
  const [systemHealth, setSystemHealth] = useState(null); // New state for VPS health
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

      // Fetch System Health (VPS)
      try {
        const sysResponse = await fetch(`${API_BASE_URL}/system/health`);
        if (sysResponse.ok) {
          const sysData = await sysResponse.json();
          setSystemHealth(sysData);
        }
      } catch (e) {
        console.error("Erro ao buscar dados de disco:", e);
      }

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

      {/* VPS Health Widget */}
      {systemHealth && systemHealth.disk ? (
        <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700 shadow-lg mb-8 animate-in fade-in slide-in-from-top-4 duration-500">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-white flex items-center gap-2">
              <Server className="text-indigo-400" size={20} />
              Saúde da Infraestrutura (VPS)
            </h3>
            <div className="flex gap-2">
              <span
                className={`px-3 py-1 rounded-full text-xs font-medium border ${
                  systemHealth.disk.status === "healthy"
                    ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
                    : systemHealth.disk.status === "warning"
                    ? "bg-amber-500/10 text-amber-400 border-amber-500/20"
                    : "bg-rose-500/10 text-rose-400 border-rose-500/20"
                }`}
              >
                DISK:{" "}
                {systemHealth.disk.status === "healthy"
                  ? "OK"
                  : systemHealth.disk.status === "warning"
                  ? "WARN"
                  : "CRIT"}
              </span>
              {systemHealth.cpu && (
                <span
                  className={`px-3 py-1 rounded-full text-xs font-medium border ${
                    systemHealth.cpu.status === "healthy"
                      ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
                      : systemHealth.cpu.status === "warning"
                      ? "bg-amber-500/10 text-amber-400 border-amber-500/20"
                      : "bg-rose-500/10 text-rose-400 border-rose-500/20"
                  }`}
                >
                  CPU:{" "}
                  {systemHealth.cpu.status === "healthy"
                    ? "OK"
                    : systemHealth.cpu.status === "warning"
                    ? "WARN"
                    : "CRIT"}
                </span>
              )}
            </div>
          </div>

          <div className="space-y-6">
            {/* Disk Usage */}
            <div>
              <div className="flex justify-between text-sm mb-2">
                <span className="text-slate-400 flex items-center gap-2">
                  <Database size={14} /> Uso de Disco
                </span>
                <span className="text-slate-200 font-medium">
                  {systemHealth.disk.used_gb} GB / {systemHealth.disk.total_gb}{" "}
                  GB
                </span>
              </div>
              <div className="w-full bg-slate-700 rounded-full h-4 overflow-hidden">
                <div
                  className={`h-full rounded-full transition-all duration-1000 ${
                    systemHealth.disk.status === "healthy"
                      ? "bg-emerald-500"
                      : systemHealth.disk.status === "warning"
                      ? "bg-amber-500"
                      : "bg-rose-500"
                  }`}
                  style={{
                    width: `${Math.min(systemHealth.disk.percent_used, 100)}%`,
                  }}
                ></div>
              </div>
              <div className="flex justify-end mt-1">
                <span className="text-xs text-slate-500">
                  {systemHealth.disk.percent_used}% utilizado
                </span>
              </div>
            </div>

            {/* CPU Usage */}
            {systemHealth.cpu && (
              <div>
                <div className="flex justify-between text-sm mb-2">
                  <span className="text-slate-400 flex items-center gap-2">
                    <Cpu size={14} /> Uso de CPU
                  </span>
                  <span className="text-slate-200 font-medium">
                    {systemHealth.cpu.percent_used}%
                  </span>
                </div>
                <div className="w-full bg-slate-700 rounded-full h-4 overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all duration-1000 ${
                      systemHealth.cpu.status === "healthy"
                        ? "bg-blue-500"
                        : systemHealth.cpu.status === "warning"
                        ? "bg-amber-500"
                        : "bg-rose-500"
                    }`}
                    style={{
                      width: `${Math.min(systemHealth.cpu.percent_used, 100)}%`,
                    }}
                  ></div>
                </div>
                <div className="flex justify-end mt-1">
                  <span className="text-xs text-slate-500">
                    {systemHealth.cpu.percent_used}% utilizado
                  </span>
                </div>
              </div>
            )}
          </div>
        </div>
      ) : (
        <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700 shadow-lg mb-8 animate-in fade-in">
          <div className="flex items-center gap-3 text-slate-400">
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-indigo-500"></div>
            <span>Carregando status da infraestrutura...</span>
          </div>
        </div>
      )}

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
