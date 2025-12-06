import React, { useState, useEffect } from "react";
import { ClipboardList, Zap, Cpu, Eye } from "lucide-react";
import PipelineCard from "./PipelineCard";
import { API_BASE_URL } from "../config";

const OperationalOverview = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await fetch(
          `${API_BASE_URL}/analytics/workflow-stats`
        );
        if (!response.ok) throw new Error("Falha ao buscar estatísticas");
        const data = await response.json();
        setStats(data);
      } catch (error) {
        console.error("Erro no OperationalOverview:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchStats();

    // Opcional: Polling a cada 30 segundos para "Tempo Real"
    const interval = setInterval(fetchStats, 30000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="mb-8">
      <h2 className="text-xl font-semibold text-white mb-4 flex items-center gap-2">
        <span className="w-2 h-8 bg-cyan-500 rounded-full"></span>
        Fluxo Operacional da Fábrica (Tempo Real)
      </h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <PipelineCard
          title="Aguardando Validação"
          count={stats?.validation}
          icon={ClipboardList}
          colorTheme="blue"
        />
        <PipelineCard
          title="Fila Expressa (Fast Track)"
          count={stats?.fast_track}
          icon={Zap}
          colorTheme="yellow"
        />
        <PipelineCard
          title="Na Fábrica (Aguardando Dev)"
          count={stats?.in_factory}
          icon={Cpu}
          colorTheme="purple"
        />
        <PipelineCard
          title="Aguardando Revisão"
          count={stats?.review}
          icon={Eye}
          colorTheme="orange"
        />
      </div>
    </div>
  );
};

export default OperationalOverview;
