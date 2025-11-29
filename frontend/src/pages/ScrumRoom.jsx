import React, { useState, useEffect } from "react";
import { toast } from "react-toastify";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  LineChart,
  Line,
} from "recharts";
import ReactMarkdown from "react-markdown";
import { API_BASE_URL } from "../config";

const ScrumRoom = () => {
  const [metrics, setMetrics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [reportLoading, setReportLoading] = useState(false);
  const [generatedReport, setGeneratedReport] = useState(null);
  const [reportType, setReportType] = useState(null);

  useEffect(() => {
    fetchMetrics();
  }, []);

  const fetchMetrics = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/scrum/dashboard`);
      if (!response.ok) throw new Error("Falha ao carregar métricas Scrum");
      const data = await response.json();
      setMetrics(data);
    } catch (error) {
      console.error(error);
      toast.error("Erro ao carregar dados da Sala Scrum.");
    } finally {
      setLoading(false);
    }
  };

  const generateReport = async (type) => {
    setReportLoading(true);
    setReportType(type);
    setGeneratedReport(null);
    try {
      const response = await fetch(
        `${API_BASE_URL}/scrum/agent/report?report_type=${type}`,
        { method: "POST" }
      );
      if (!response.ok) throw new Error("Falha ao gerar relatório");
      const data = await response.json();
      setGeneratedReport(data.report);
      toast.success("Relatório gerado com sucesso!");
    } catch (error) {
      console.error(error);
      toast.error("Erro ao gerar relatório com IA.");
    } finally {
      setReportLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-full">
        <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-cyan-500"></div>
      </div>
    );
  }

  if (!metrics) return null;

  return (
    <div className="page-content flex flex-col h-full overflow-y-auto p-6 space-y-6">
      <header className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">
            Sala Scrum Agile 🚀
          </h1>
          <p className="text-slate-400">
            Monitoramento de Indicadores, Saúde do Time e Agente Scrum IA.
          </p>
        </div>
        <div className="flex space-x-3">
          <button
            onClick={() => generateReport("review")}
            className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded shadow transition-colors"
          >
            📝 Sprint Review
          </button>
          <button
            onClick={() => generateReport("retro")}
            className="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded shadow transition-colors"
          >
            🔄 Retrospectiva
          </button>
          <button
            onClick={() => generateReport("planning")}
            className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded shadow transition-colors"
          >
            📅 Planning
          </button>
        </div>
      </header>

      {/* --- REPORT SECTION (Collapsible/Conditional) --- */}
      {(reportLoading || generatedReport) && (
        <div className="card bg-slate-800 border border-slate-700 p-6 rounded-lg shadow-lg animate-fade-in">
          <div className="flex justify-between items-center mb-4 border-b border-slate-700 pb-2">
            <h2 className="text-xl font-bold text-cyan-400 flex items-center">
              🤖 Agente Scrum:{" "}
              {reportType === "review"
                ? "Sprint Review"
                : reportType === "retro"
                ? "Retrospectiva"
                : "Planning"}
            </h2>
            <button
              onClick={() => setGeneratedReport(null)}
              className="text-slate-400 hover:text-white"
            >
              ✕
            </button>
          </div>

          {reportLoading ? (
            <div className="flex items-center space-x-3 py-8 justify-center">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-cyan-500"></div>
              <span className="text-slate-300 animate-pulse">
                Analisando métricas e gerando insights...
              </span>
            </div>
          ) : (
            <div className="prose prose-invert max-w-none">
              <ReactMarkdown>{generatedReport}</ReactMarkdown>
            </div>
          )}
        </div>
      )}

      {/* --- DASHBOARD GRID --- */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* 1. FLUXO */}
        <div className="card bg-slate-800/50 p-5 border border-slate-700 rounded-lg">
          <h3 className="text-lg font-semibold text-blue-400 mb-4 flex items-center">
            🌊 Indicadores de Fluxo
          </h3>
          <div className="grid grid-cols-2 gap-4">
            <StatBox
              label="Lead Time Médio"
              value={`${metrics.flow.lead_time_avg_days} dias`}
            />
            <StatBox
              label="Cycle Time Médio"
              value={`${metrics.flow.cycle_time_avg_days} dias`}
            />
            <StatBox label="WIP Atual" value={metrics.flow.wip} />
            <StatBox
              label="Throughput"
              value={metrics.flow.throughput_sprint}
            />
            <div className="col-span-2">
              <StatBox
                label="Aging WIP Médio"
                value={`${metrics.flow.aging_wip_avg_hours}h`}
              />
            </div>
          </div>
        </div>

        {/* 2. ENTREGA (Mocked Chart for now) */}
        <div className="card bg-slate-800/50 p-5 border border-slate-700 rounded-lg">
          <h3 className="text-lg font-semibold text-green-400 mb-4 flex items-center">
            📦 Entrega & Produtividade
          </h3>
          <div className="h-48">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart
                data={[
                  { name: "S-2", pf: 80 },
                  { name: "S-1", pf: 95 },
                  { name: "Atual", pf: metrics.flow.throughput_sprint * 5 }, // Mock PF conversion
                ]}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                <XAxis dataKey="name" stroke="#94a3b8" />
                <YAxis stroke="#94a3b8" />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1e293b",
                    borderColor: "#334155",
                  }}
                />
                <Bar dataKey="pf" fill="#4ade80" name="Velocity (PF)" />
              </BarChart>
            </ResponsiveContainer>
          </div>
          <div className="mt-2 text-center text-sm text-slate-400">
            Velocity Recente
          </div>
        </div>

        {/* 3. QUALIDADE */}
        <div className="card bg-slate-800/50 p-5 border border-slate-700 rounded-lg">
          <h3 className="text-lg font-semibold text-red-400 mb-4 flex items-center">
            🛡️ Qualidade
          </h3>
          <div className="space-y-4">
            <div className="flex justify-between items-center p-3 bg-slate-700/30 rounded">
              <span className="text-slate-300">Bugs na Sprint</span>
              <span className="text-2xl font-bold text-red-400">
                {metrics.quality.bugs_count}
              </span>
            </div>
            <div className="flex justify-between items-center p-3 bg-slate-700/30 rounded">
              <span className="text-slate-300">Itens com Retrabalho</span>
              <span className="text-2xl font-bold text-orange-400">
                {metrics.quality.rework_count}
              </span>
            </div>
            <div className="flex justify-between items-center p-3 bg-slate-700/30 rounded">
              <span className="text-slate-300">Taxa de Retrabalho</span>
              <span className="text-2xl font-bold text-yellow-400">
                {metrics.quality.rework_rate}%
              </span>
            </div>
          </div>
        </div>

        {/* 4. SAÚDE DO TIME */}
        <div className="card bg-slate-800/50 p-5 border border-slate-700 rounded-lg">
          <h3 className="text-lg font-semibold text-pink-400 mb-4 flex items-center">
            ❤️ Saúde do Time
          </h3>
          <div className="grid grid-cols-2 gap-4">
            <StatBox
              label="Bloqueios"
              value={metrics.health.blockers_count}
              color="text-red-500"
            />
            <StatBox
              label="Moral do Time"
              value={`${metrics.health.team_morale}/5`}
              color="text-pink-500"
            />
            <StatBox
              label="Turnover"
              value={`${metrics.health.turnover_rate}%`}
            />
            <div className="col-span-2 p-3 bg-slate-700/30 rounded text-center">
              <span className="text-xs text-slate-400 uppercase tracking-wider">
                Status Geral
              </span>
              <div className="text-lg font-bold text-green-400 mt-1">
                Saudável
              </div>
            </div>
          </div>
        </div>

        {/* 5. PREVISIBILIDADE */}
        <div className="card bg-slate-800/50 p-5 border border-slate-700 rounded-lg">
          <h3 className="text-lg font-semibold text-purple-400 mb-4 flex items-center">
            🔮 Previsibilidade
          </h3>
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <span className="text-slate-400">Acurácia da Sprint</span>
              <span className="font-bold text-white">-- %</span>
            </div>
            <div className="w-full bg-slate-700 rounded-full h-2.5">
              <div
                className="bg-purple-600 h-2.5 rounded-full"
                style={{ width: "0%" }}
              ></div>
            </div>

            <div className="pt-4 border-t border-slate-700">
              <div className="flex justify-between items-center mb-1">
                <span className="text-slate-300">Demandas Não Planejadas</span>
                <span className="text-xl font-bold text-orange-400">
                  {metrics.predictability.unplanned_items}
                </span>
              </div>
              <p className="text-xs text-slate-500">
                Itens adicionados após o início da sprint.
              </p>
            </div>
          </div>
        </div>

        {/* 6. MATURIDADE */}
        <div className="card bg-slate-800/50 p-5 border border-slate-700 rounded-lg">
          <h3 className="text-lg font-semibold text-yellow-400 mb-4 flex items-center">
            🏆 Maturidade Ágil
          </h3>
          <div className="flex flex-col items-center justify-center h-full space-y-4">
            <div className="text-4xl font-bold text-yellow-500">
              {metrics.maturity.adherence_score}
            </div>
            <span className="text-slate-400">Score de Aderência (0-10)</span>

            <div className="w-full grid grid-cols-2 gap-2 mt-4">
              <div className="bg-slate-700/50 p-2 rounded text-center">
                <div className="text-xs text-slate-500">Backlog Health</div>
                <div className="font-bold text-green-400">
                  {metrics.maturity.backlog_health}
                </div>
              </div>
              <div className="bg-slate-700/50 p-2 rounded text-center">
                <div className="text-xs text-slate-500">Cerimônias</div>
                <div className="font-bold text-green-400">100%</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const StatBox = ({ label, value, color = "text-white" }) => (
  <div className="bg-slate-700/30 p-3 rounded flex flex-col items-center justify-center">
    <span className="text-xs text-slate-400 uppercase tracking-wider mb-1 text-center">
      {label}
    </span>
    <span className={`text-xl font-bold ${color}`}>{value}</span>
  </div>
);

export default ScrumRoom;
