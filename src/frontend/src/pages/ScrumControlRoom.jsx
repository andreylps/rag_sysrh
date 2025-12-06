import React, { useState, useEffect } from "react";
import axios from "axios";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import {
  ClipboardDocumentCheckIcon,
  ChartBarIcon,
  ExclamationTriangleIcon,
  ClockIcon,
  DocumentTextIcon,
  PrinterIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import { API_BASE_URL } from "../config";

const ScrumControlRoom = () => {
  const [activeTab, setActiveTab] = useState("dashboard");
  const [sprintData, setSprintData] = useState(null);
  const [burndownData, setBurndownData] = useState([]);
  const [reports, setReports] = useState([]);
  const [selectedReport, setSelectedReport] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [sprintRes, burndownRes, reportsRes] = await Promise.all([
          axios.get(`${API_BASE_URL}/scrum/current-sprint`),
          axios.get(`${API_BASE_URL}/scrum/burndown-data`),
          axios.get(`${API_BASE_URL}/scrum/reports`),
        ]);
        setSprintData(sprintRes.data);
        setBurndownData(burndownRes.data);
        setReports(reportsRes.data);
      } catch (error) {
        console.error("Error fetching Scrum data:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const handlePrint = () => {
    window.print();
  };

  if (loading)
    return <div className="p-8 text-white">Carregando Sala de Controle...</div>;

  const renderDashboard = () => (
    <div className="space-y-6">
      {/* Cards Métricos */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-gray-800 p-4 rounded-lg border border-gray-700">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm">Sprint Atual</p>
              <p className="text-xl font-bold text-white">{sprintData?.id}</p>
            </div>
            <ClipboardDocumentCheckIcon className="h-8 w-8 text-blue-400" />
          </div>
          <p className="text-xs text-gray-500 mt-2">
            {new Date(sprintData?.start_date).toLocaleDateString()} -{" "}
            {new Date(sprintData?.end_date).toLocaleDateString()}
          </p>
        </div>

        <div className="bg-gray-800 p-4 rounded-lg border border-gray-700">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm">Progresso (PF)</p>
              <p className="text-xl font-bold text-white">
                {sprintData?.completed_pf} / {sprintData?.total_pf}
              </p>
            </div>
            <ChartBarIcon className="h-8 w-8 text-green-400" />
          </div>
          <div className="w-full bg-gray-700 h-2 rounded-full mt-2">
            <div
              className="bg-green-500 h-2 rounded-full"
              style={{
                width: `${
                  (sprintData?.completed_pf / sprintData?.total_pf) * 100
                }%`,
              }}
            ></div>
          </div>
        </div>

        <div
          className={`bg-gray-800 p-4 rounded-lg border ${
            sprintData?.issues_at_risk > 0
              ? "border-red-500"
              : "border-gray-700"
          }`}
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm">Risco SLA</p>
              <p
                className={`text-xl font-bold ${
                  sprintData?.issues_at_risk > 0 ? "text-red-400" : "text-white"
                }`}
              >
                {sprintData?.issues_at_risk} Issues
              </p>
            </div>
            <ExclamationTriangleIcon
              className={`h-8 w-8 ${
                sprintData?.issues_at_risk > 0
                  ? "text-red-500"
                  : "text-gray-400"
              }`}
            />
          </div>
          <p className="text-xs text-gray-500 mt-2">Monitoramento Ativo</p>
        </div>

        <div className="bg-gray-800 p-4 rounded-lg border border-gray-700">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm">Dias Restantes</p>
              <p className="text-xl font-bold text-white">
                {Math.max(
                  0,
                  Math.ceil(
                    (new Date(sprintData?.end_date) - new Date()) /
                      (1000 * 60 * 60 * 24)
                  )
                )}
              </p>
            </div>
            <ClockIcon className="h-8 w-8 text-purple-400" />
          </div>
          <p className="text-xs text-gray-500 mt-2">Ciclo de 14 dias</p>
        </div>
      </div>

      {/* Burndown Chart */}
      <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
        <h3 className="text-lg font-semibold text-white mb-4">
          Burndown Chart
        </h3>
        <div className="h-80 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={burndownData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
              <XAxis
                dataKey="day"
                stroke="#9CA3AF"
                tickFormatter={(str) => str.split("-")[2]}
              />
              <YAxis stroke="#9CA3AF" />
              <Tooltip
                contentStyle={{
                  backgroundColor: "#1F2937",
                  borderColor: "#374151",
                  color: "#fff",
                }}
                itemStyle={{ color: "#fff" }}
              />
              <Legend />
              <Line
                type="monotone"
                dataKey="ideal"
                stroke="#6B7280"
                strokeDasharray="5 5"
                name="Ideal"
                dot={false}
              />
              <Line
                type="monotone"
                dataKey="actual"
                stroke="#10B981"
                strokeWidth={2}
                name="Real"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );

  const renderKanban = () => {
    const columns = {
      todo: { title: "A Fazer", items: [] },
      dev: { title: "Em Desenvolvimento", items: [] },
      qa: { title: "Em QA/Validação", items: [] },
      done: { title: "Concluído", items: [] },
    };

    sprintData?.issues_data?.forEach((issue) => {
      let status = "todo";
      if (issue.status === "done") status = "done";
      else if (issue.labels.includes("status:em-desenvolvimento"))
        status = "dev";
      else if (
        issue.labels.some(
          (l) =>
            l.includes("validacao") ||
            l.includes("homologacao") ||
            l.includes("review")
        )
      )
        status = "qa";

      columns[status].items.push(issue);
    });

    return (
      <div className="grid grid-cols-4 gap-4 h-full overflow-x-auto">
        {Object.entries(columns).map(([key, col]) => (
          <div key={key} className="bg-gray-800 rounded-lg p-4 min-h-[500px]">
            <h3 className="text-white font-semibold mb-4 flex justify-between">
              {col.title}
              <span className="bg-gray-700 px-2 py-0.5 rounded text-sm">
                {col.items.length}
              </span>
            </h3>
            <div className="space-y-3">
              {col.items.map((issue) => {
                const isRisk = issue.labels.some((l) => l.includes("risco:"));
                const isBlocked = issue.labels.some((l) =>
                  l.includes("bloqueado:")
                );

                return (
                  <div
                    key={issue.id}
                    className={`bg-gray-700 p-3 rounded border-l-4 ${
                      isBlocked
                        ? "border-purple-500"
                        : isRisk
                        ? "border-red-500"
                        : "border-blue-500"
                    } hover:bg-gray-600 transition-colors cursor-pointer`}
                  >
                    <div className="flex justify-between items-start mb-2">
                      <span className="text-xs text-gray-400">#{issue.id}</span>
                      <span className="text-xs bg-gray-600 px-1 rounded text-gray-300">
                        {issue.pf} PF
                      </span>
                    </div>
                    <p className="text-white text-sm font-medium mb-2">
                      {issue.title}
                    </p>
                    <div className="flex flex-wrap gap-1">
                      {issue.labels
                        .filter(
                          (l) => l.includes("risco") || l.includes("bloqueado")
                        )
                        .map((l) => (
                          <span
                            key={l}
                            className="text-[10px] px-1 py-0.5 rounded bg-red-900 text-red-200"
                          >
                            {l.split(":")[1]}
                          </span>
                        ))}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        ))}
      </div>
    );
  };

  const renderReports = () => (
    <div className="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden">
      <table className="w-full text-left text-gray-400">
        <thead className="bg-gray-900 text-gray-200 uppercase text-xs">
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
                className="border-b border-gray-700 hover:bg-gray-700"
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
    <div className="p-6 bg-gray-900 min-h-screen print:hidden">
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

      <header className="mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-white">
            Sala de Controle Scrum
          </h1>
          <p className="text-gray-400 mt-1">
            Gestão de Sprints e Riscos em Tempo Real
          </p>
        </div>
        <div className="flex space-x-2 bg-gray-800 p-1 rounded-lg">
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
            onClick={() => setActiveTab("kanban")}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              activeTab === "kanban"
                ? "bg-blue-600 text-white"
                : "text-gray-400 hover:text-white"
            }`}
          >
            Kanban
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
      </header>

      {activeTab === "dashboard" && renderDashboard()}
      {activeTab === "kanban" && renderKanban()}
      {activeTab === "reports" && renderReports()}
    </div>
  );
};

export default ScrumControlRoom;
