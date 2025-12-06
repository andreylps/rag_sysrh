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
import {
  DocumentTextIcon,
  PrinterIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import { API_BASE_URL } from "../config";

const ScrumRoom = () => {
  const [activeTab, setActiveTab] = useState("dashboard");
  const [metrics, setMetrics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [reportLoading, setReportLoading] = useState(false);
  const [generatedReport, setGeneratedReport] = useState(null);
  const [reportType, setReportType] = useState(null);
  const [reports, setReports] = useState([]);
  const [selectedReport, setSelectedReport] = useState(null);

  useEffect(() => {
    fetchMetrics();
    fetchReports();
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

  const fetchReports = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/scrum/reports`);
      if (response.ok) {
        const data = await response.json();
        setReports(data);
      }
    } catch (error) {
      console.error("Erro ao carregar relatórios:", error);
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

  const handlePrint = () => {
    window.print();
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-full">
        <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-cyan-500"></div>
      </div>
    );
  }

  if (!metrics) return null;

  const renderReports = () => (
    <div className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
      <table className="w-full text-left text-slate-400">
        <thead className="bg-slate-900 text-slate-200 uppercase text-xs">
          <tr>
            <th className="px-6 py-3">Sprint</th>
            <th className="px-6 py-3">Data Fechamento</th>
            <th className="px-6 py-3">Velocidade (%)</th>
            <th className="px-6 py-3">PF Entregue</th>
            <th className="px-6 py-3">Spilled Issues</th>
            <th className="px-6 py-3">Ações</th>
          </tr>
        </thead>
        <tbody>
          {reports.length === 0 ? (
            <tr>
              <td colSpan="6" className="px-6 py-4 text-center">
                Nenhum relatório encontrado.
              </td>
            </tr>
          ) : (
            reports.map((report) => (
              <tr
                key={report.sprint_id}
                className="border-b border-slate-700 hover:bg-slate-700"
              >
                <td className="px-6 py-4 font-medium text-white">
                  {report.sprint_id}
                </td>
                <td className="px-6 py-4">
                  {new Date(report.close_date).toLocaleDateString()}
                </td>
                <td className="px-6 py-4">
                  <span
                    className={`px-2 py-1 rounded text-xs ${
                      report.velocity_achieved >= 90
                        ? "bg-green-900 text-green-200"
                        : "bg-yellow-900 text-yellow-200"
                    }`}
                  >
                    {report.velocity_achieved}%
                  </span>
                </td>
                <td className="px-6 py-4">
                  {report.delivered_pf} / {report.planned_pf}
                </td>
                <td className="px-6 py-4">{report.spilled_issues_count}</td>
                <td className="px-6 py-4">
                  <button
                    onClick={() => setSelectedReport(report)}
                    className="text-blue-400 hover:text-blue-300 flex items-center gap-1"
                  >
                    <DocumentTextIcon className="h-4 w-4" /> Ver Relatório
                  </button>
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );

  const renderReportModal = () => {
    if (!selectedReport) return null;

    return (
      <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50 p-4 print:p-0 print:bg-white print:static">
        <div className="bg-white text-gray-900 w-full max-w-4xl max-h-[90vh] overflow-y-auto rounded-lg shadow-xl print:shadow-none print:max-w-none print:max-h-none print:w-full print:h-full print:rounded-none">
          {/* Header (Print Only or Modal) */}
          <div className="p-8 border-b border-gray-200 flex justify-between items-start">
            <div>
              <h2 className="text-3xl font-bold text-gray-900">
                Relatório de Fechamento de Sprint
              </h2>
              <p className="text-gray-500 mt-1">
                Sprint ID: {selectedReport.sprint_id}
              </p>
              <p className="text-gray-500">
                Data: {new Date(selectedReport.close_date).toLocaleDateString()}
              </p>
            </div>
            <div className="flex gap-2 print:hidden">
              <button
                onClick={handlePrint}
                className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
              >
                <PrinterIcon className="h-5 w-5" /> Imprimir
              </button>
              <button
                onClick={() => setSelectedReport(null)}
                className="p-2 text-gray-500 hover:text-gray-700"
              >
                <XMarkIcon className="h-6 w-6" />
              </button>
            </div>
          </div>

          <div className="p-8 space-y-8">
            {/* Metrics Grid */}
            <div className="grid grid-cols-4 gap-6">
              <div className="bg-gray-50 p-4 rounded border border-gray-200">
                <p className="text-sm text-gray-500 uppercase">Velocidade</p>
                <p className="text-2xl font-bold text-gray-900">
                  {selectedReport.velocity_achieved}%
                </p>
              </div>
              <div className="bg-gray-50 p-4 rounded border border-gray-200">
                <p className="text-sm text-gray-500 uppercase">Entregas (PF)</p>
                <p className="text-2xl font-bold text-gray-900">
                  {selectedReport.delivered_pf}{" "}
                  <span className="text-sm text-gray-400 font-normal">
                    / {selectedReport.planned_pf}
                  </span>
                </p>
              </div>
              <div className="bg-gray-50 p-4 rounded border border-gray-200">
                <p className="text-sm text-gray-500 uppercase">
                  Spilled Issues
                </p>
                <p className="text-2xl font-bold text-red-600">
                  {selectedReport.spilled_issues_count}
                </p>
              </div>
              <div className="bg-gray-50 p-4 rounded border border-gray-200">
                <p className="text-sm text-gray-500 uppercase">Bloqueios QA</p>
                <p className="text-2xl font-bold text-purple-600">
                  {selectedReport.blocker_count}
                </p>
              </div>
            </div>

            {/* Analysis Section */}
            <div>
              <h3 className="text-xl font-bold text-gray-800 mb-4 border-b pb-2">
                Análise do Ciclo
              </h3>
              <p className="text-gray-700 leading-relaxed">
                A sprint {selectedReport.sprint_id} atingiu{" "}
                {selectedReport.velocity_achieved}% da capacidade planejada.
                Foram entregues {selectedReport.delivered_pf} pontos de função.
                {selectedReport.spilled_issues_count > 0
                  ? ` Houve ${selectedReport.spilled_issues_count} itens não entregues (spilled) que retornaram ao backlog.`
                  : " Todos os itens planejados foram entregues."}
                {selectedReport.blocker_count > 0 &&
                  ` Detectamos ${selectedReport.blocker_count} bloqueios críticos de qualidade durante o ciclo.`}
              </p>
            </div>

            {/* Footer */}
            <div className="mt-12 pt-8 border-t border-gray-200 text-center text-sm text-gray-400">
              Gerado automaticamente pelo Agente Scrum Master - RAG_SYSRH
            </div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="page-content flex flex-col h-full overflow-y-auto p-6 space-y-6 print:hidden">
      <style>{`
        @media print {
          .app-layout, .sidebar, header, .print\\:hidden {
            display: none !important;
          }
          .print\\:block {
            display: block !important;
          }
          body {
            background-color: white !important;
            color: black !important;
          }
          /* Ensure modal content is visible and takes full width */
          .fixed {
            position: static !important;
            background: white !important;
          }
        }
      `}</style>

      {selectedReport && renderReportModal()}

      <header className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">
            Sala Scrum Agile 🚀
          </h1>
          <p className="text-slate-400">
            Monitoramento de Indicadores, Saúde do Time e Agente Scrum IA.
          </p>
        </div>
        <div className="flex space-x-3 items-center">
          <div className="flex space-x-2 bg-slate-800 p-1 rounded-lg mr-4">
            <button
              onClick={() => setActiveTab("dashboard")}
              className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                activeTab === "dashboard"
                  ? "bg-blue-600 text-white"
                  : "text-gray-400 hover:text-white"
              }`}
            >
              Dashboard
            </button>
            <button
              onClick={() => setActiveTab("reports")}
              className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                activeTab === "reports"
                  ? "bg-blue-600 text-white"
                  : "text-gray-400 hover:text-white"
              }`}
            >
              Relatórios de Ciclo
            </button>
          </div>

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

      {activeTab === "dashboard" && (
        <>
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
                    <span className="text-slate-300">
                      Demandas Não Planejadas
                    </span>
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
                <span className="text-slate-400">
                  Score de Aderência (0-10)
                </span>

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
        </>
      )}

      {activeTab === "reports" && renderReports()}
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
