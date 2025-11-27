import React, { useState, useEffect } from "react";
import {
  ShieldCheck,
  AlertTriangle,
  FileText,
  Calendar as CalendarIcon,
  Activity,
  CheckCircle,
  XCircle,
  Clock,
  TrendingUp,
  Code,
  Lock,
  Eye,
  BarChart,
  ArrowRight,
} from "lucide-react";
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  Tooltip,
  Legend,
} from "recharts";

const QualityControlRoom = () => {
  const [activeTab, setActiveTab] = useState("dashboard");
  const [metrics, setMetrics] = useState({
    compliance_rate: 0,
    active_bottlenecks: 0,
    stale_issues_count: 0,
    doc_failures_count: 0,
    failure_distribution: [],
    total_audits: 0,
  });
  const [alerts, setAlerts] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  const [auditSchedule, setAuditSchedule] = useState([]);
  const [pdcaReports, setPdcaReports] = useState([]);

  useEffect(() => {
    fetchMetrics();
    fetchAuditData();
  }, []);

  const fetchMetrics = async () => {
    try {
      const response = await fetch(
        "http://localhost:8080/api/v1/quality/metrics"
      );
      if (response.ok) {
        const data = await response.json();
        setMetrics(data);
        setAlerts(data.alerts || []);
      }
    } catch (error) {
      console.error("Erro ao buscar métricas:", error);
    }
  };

  const fetchAuditData = async () => {
    try {
      const [scheduleRes, reportsRes] = await Promise.all([
        fetch("http://localhost:8080/api/v1/audit/schedule"),
        fetch("http://localhost:8080/api/v1/audit/reports"),
      ]);

      if (scheduleRes.ok) {
        const scheduleData = await scheduleRes.json();
        setAuditSchedule(scheduleData);
      }

      if (reportsRes.ok) {
        const reportsData = await reportsRes.json();
        setPdcaReports(reportsData);
      }
    } catch (error) {
      console.error("Erro ao buscar dados de auditoria:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const renderDashboard = () => (
    <div className="space-y-6 animate-in fade-in duration-500">
      {/* Top Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-lg">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-slate-400 text-sm font-medium">
                Alertas Ativos
              </p>
              <h3 className="text-3xl font-bold text-white mt-2">
                {metrics.active_bottlenecks}
              </h3>
            </div>
            <div className="p-3 bg-red-500/20 rounded-lg">
              <AlertTriangle className="text-red-400" size={24} />
            </div>
          </div>
          <p className="text-xs text-slate-500 mt-4">
            {metrics.doc_failures_count} falhas de doc,{" "}
            {metrics.stale_issues_count} estagnados
          </p>
        </div>

        <div className="bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-lg">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-slate-400 text-sm font-medium">
                Taxa de Conformidade
              </p>
              <h3 className="text-3xl font-bold text-emerald-400 mt-2">
                {metrics.compliance_rate}%
              </h3>
            </div>
            <div className="p-3 bg-emerald-500/20 rounded-lg">
              <ShieldCheck className="text-emerald-400" size={24} />
            </div>
          </div>
          <p className="text-xs text-slate-500 mt-4">
            Baseado em {metrics.total_audits} auditorias
          </p>
        </div>

        <div className="bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-lg">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-slate-400 text-sm font-medium">
                Auditorias Realizadas
              </p>
              <h3 className="text-3xl font-bold text-blue-400 mt-2">
                {metrics.total_audits}
              </h3>
            </div>
            <div className="p-3 bg-blue-500/20 rounded-lg">
              <Activity className="text-blue-400" size={24} />
            </div>
          </div>
          <p className="text-xs text-slate-500 mt-4">
            Total acumulado no ciclo
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Alerts List */}
        <div className="bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-lg">
          <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <AlertTriangle size={20} className="text-amber-400" />
            Alertas Recentes
          </h3>
          <div className="space-y-3 max-h-[300px] overflow-y-auto pr-2 custom-scrollbar">
            {alerts.length === 0 ? (
              <div className="text-center py-8 text-slate-500">
                <CheckCircle
                  size={40}
                  className="mx-auto mb-2 text-slate-600"
                />
                <p>Nenhum alerta ativo. Tudo certo!</p>
              </div>
            ) : (
              alerts.map((alert, index) => (
                <div
                  key={index}
                  className="p-4 bg-slate-900/50 rounded-lg border border-slate-700 flex gap-3 items-start hover:bg-slate-900/80 transition-colors"
                >
                  <div className="mt-1">
                    {alert.category === "document_qa_failure" ? (
                      <FileText className="text-red-400" size={18} />
                    ) : (
                      <Clock className="text-amber-400" size={18} />
                    )}
                  </div>
                  <div>
                    <p className="text-slate-200 text-sm font-medium">
                      {alert.message}
                    </p>
                    <div className="flex items-center gap-2 mt-2">
                      <span className="text-xs text-slate-500">
                        {new Date(alert.timestamp).toLocaleString()}
                      </span>
                      {alert.issue_number && (
                        <span className="text-xs bg-slate-700 px-2 py-0.5 rounded text-slate-300">
                          #{alert.issue_number}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Failure Distribution Chart */}
        <div className="bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-lg">
          <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <ShieldCheck size={20} className="text-indigo-400" />
            Distribuição de Falhas (ISO)
          </h3>
          <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={metrics.failure_distribution}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {metrics.failure_distribution.map((entry, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={
                        ["#3b82f6", "#10b981", "#f59e0b", "#ef4444"][index % 4]
                      }
                    />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1e293b",
                    borderColor: "#334155",
                    color: "#f1f5f9",
                  }}
                />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );

  const triggerQuarterlyPlan = async () => {
    if (
      window.confirm("Deseja planejar automaticamente o próximo trimestre?")
    ) {
      try {
        // Endpoint simulado - na prática chamaria o scheduler
        // Como não expus endpoint para isso, vou simular via trigger-sprint ou criar um novo endpoint se necessário.
        // Pelo prompt, o agente "planeja". Vou assumir que o backend já fez isso ou vou expor um endpoint rápido.
        // Vou adicionar um endpoint rápido no router.py ou assumir que o usuário vai rodar o script.
        // Para facilitar, vou adicionar um botão que chama um endpoint novo (que precisarei criar rapidinho ou mockar aqui).
        // Vou assumir que o backend expõe POST /api/v1/audit/plan-quarterly
        const res = await fetch(
          "http://localhost:8080/api/v1/audit/plan-quarterly",
          { method: "POST" }
        );
        if (res.ok) {
          alert("Planejamento trimestral gerado!");
          fetchAuditData();
        } else {
          alert("Erro ao planejar.");
        }
      } catch (e) {
        console.error(e);
        alert("Erro de conexão.");
      }
    }
  };

  const getAuditIcon = (type) => {
    switch (type) {
      case "SPRINT_AUDIT":
        return <Activity className="text-blue-400" />;
      case "DOC_AUDIT":
        return <FileText className="text-yellow-400" />;
      case "CODE_AUDIT":
        return <Code className="text-purple-400" />;
      case "SECURITY_AUDIT":
        return <Lock className="text-red-400" />;
      case "CODEREVIEW_AUDIT":
        return <Eye className="text-cyan-400" />;
      case "QUARTERLY_REPORT":
        return <BarChart className="text-green-400" />;
      default:
        return <CalendarIcon className="text-slate-400" />;
    }
  };

  const [currentMonth, setCurrentMonth] = useState(new Date());

  const getDaysInMonth = (date) => {
    const year = date.getFullYear();
    const month = date.getMonth();
    const days = new Date(year, month + 1, 0).getDate();
    const firstDay = new Date(year, month, 1).getDay();
    return { days, firstDay };
  };

  const changeMonth = (offset) => {
    setCurrentMonth(
      new Date(currentMonth.setMonth(currentMonth.getMonth() + offset))
    );
  };

  const renderCalendar = () => {
    const { days, firstDay } = getDaysInMonth(currentMonth);
    const daysArray = Array.from({ length: days }, (_, i) => i + 1);
    const blanks = Array.from({ length: firstDay }, (_, i) => i);

    const monthName = currentMonth.toLocaleString("default", {
      month: "long",
      year: "numeric",
    });

    const getEventsForDay = (day) => {
      return auditSchedule.filter((item) => {
        if (!item.scheduled_date) return false;
        // Normalizar data (substituir espaço por T se necessário)
        const dateStr = item.scheduled_date.replace(" ", "T");
        const itemDate = new Date(dateStr);

        if (isNaN(itemDate.getTime())) return false;

        // Normalizar para evitar problemas de fuso horário
        // Comparar dia, mês e ano explicitamente
        return (
          itemDate.getDate() === day &&
          itemDate.getMonth() === currentMonth.getMonth() &&
          itemDate.getFullYear() === currentMonth.getFullYear()
        );
      });
    };

    const getAuditLabel = (type) => {
      switch (type) {
        case "SPRINT_AUDIT":
          return "Auditoria Sprint";
        case "DOC_AUDIT":
          return "Auditoria Doc";
        case "CODE_AUDIT":
          return "Auditoria Software";
        case "SECURITY_AUDIT":
          return "Auditoria Segurança";
        case "CODEREVIEW_AUDIT":
          return "Code Review";
        case "QUARTERLY_REPORT":
          return "Auditoria Trimestral";
        case "DAILY_CHECK":
          return "Check Diário";
        default:
          return type;
      }
    };

    return (
      <div className="bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-lg animate-in fade-in duration-500">
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center gap-4">
            <h3 className="text-xl font-bold text-white flex items-center gap-2 capitalize">
              <CalendarIcon className="text-indigo-400" />
              {monthName}
            </h3>
            <div className="flex gap-1">
              <button
                onClick={() => changeMonth(-1)}
                className="p-1 hover:bg-slate-700 rounded text-slate-400"
              >
                &lt;
              </button>
              <button
                onClick={() => changeMonth(1)}
                className="p-1 hover:bg-slate-700 rounded text-slate-400"
              >
                &gt;
              </button>
            </div>
          </div>

          <div className="flex gap-2">
            <button
              onClick={triggerQuarterlyPlan}
              className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg text-sm font-medium transition-colors"
            >
              Planejar Trimestre (Regras Novas)
            </button>
            <button
              onClick={async () => {
                if (
                  window.confirm(
                    "Deseja disparar manualmente uma Auditoria de Sprint agora?"
                  )
                ) {
                  try {
                    const res = await fetch(
                      "http://localhost:8080/api/v1/audit/trigger-sprint",
                      { method: "POST" }
                    );
                    if (res.ok) {
                      alert("Auditoria disparada com sucesso!");
                      fetchAuditData();
                    } else {
                      alert("Erro ao disparar auditoria.");
                    }
                  } catch (e) {
                    console.error(e);
                    alert("Erro de conexão.");
                  }
                }
              }}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg text-sm font-medium transition-colors"
            >
              Disparar Sprint Audit
            </button>
          </div>
        </div>

        {/* Calendar Grid */}
        <div className="grid grid-cols-7 gap-px bg-slate-700 border border-slate-700 rounded-lg overflow-hidden">
          {/* Header */}
          {["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"].map((day) => (
            <div
              key={day}
              className="bg-slate-800 p-2 text-center text-xs font-semibold text-slate-400 uppercase"
            >
              {day}
            </div>
          ))}

          {/* Blanks */}
          {blanks.map((blank) => (
            <div key={`blank-${blank}`} className="bg-slate-900/50 h-32"></div>
          ))}

          {/* Days */}
          {daysArray.map((day) => {
            const events = getEventsForDay(day);

            const isToday =
              day === new Date().getDate() &&
              currentMonth.getMonth() === new Date().getMonth() &&
              currentMonth.getFullYear() === new Date().getFullYear();

            // Determinar se o dia deve ser laranja (se tiver auditoria importante)
            const hasMajorAudit = events.some((e) =>
              [
                "SPRINT_AUDIT",
                "DOC_AUDIT",
                "QUARTERLY_REPORT",
                "CODE_AUDIT",
                "SECURITY_AUDIT",
              ].includes(e.audit_type)
            );

            const dayBgClass = hasMajorAudit
              ? "bg-orange-500/20 border-orange-500/50 hover:bg-orange-500/30"
              : isToday
              ? "bg-indigo-900/20 hover:bg-slate-800/50"
              : "bg-slate-900/80 hover:bg-slate-800/50";

            return (
              <div
                key={day}
                className={`${dayBgClass} h-32 p-2 border-t border-slate-800 transition-colors overflow-y-auto custom-scrollbar relative`}
              >
                <span
                  className={`text-sm font-bold ${
                    hasMajorAudit
                      ? "text-orange-200"
                      : isToday
                      ? "text-indigo-400"
                      : "text-slate-500"
                  }`}
                >
                  {day}
                </span>

                <div className="mt-1 space-y-1">
                  {events.map((event, idx) => {
                    if (event.audit_type === "DAILY_CHECK") return null; // Ocultar daily check para não poluir se tiver outros? Ou mostrar pequeno?
                    // O usuário pediu "escrito auditoria trimestral", etc.

                    return (
                      <div
                        key={idx}
                        className={`text-[10px] px-1.5 py-0.5 rounded flex items-center gap-1 cursor-help group relative ${
                          event.audit_type === "QUARTERLY_REPORT"
                            ? "bg-green-500/30 text-green-200 font-bold"
                            : event.audit_type === "SPRINT_AUDIT"
                            ? "bg-blue-500/30 text-blue-200"
                            : "bg-slate-800/50 text-slate-300"
                        }`}
                        title={`${getAuditLabel(event.audit_type)} - ${
                          event.status
                        }`}
                      >
                        {/* Ícone de Status */}
                        {event.status === "COMPLETED" ? (
                          <CheckCircle size={10} className="text-emerald-400" />
                        ) : event.status === "RUNNING" ? (
                          <Activity
                            size={10}
                            className="text-blue-400 animate-pulse"
                          />
                        ) : (
                          <Clock size={10} className="text-slate-500" />
                        )}

                        <span className="truncate">
                          {getAuditLabel(event.audit_type)}
                        </span>
                      </div>
                    );
                  })}
                  {/* Se tiver daily check e mais nada, mostrar algo discreto? Ou o usuário quer ver tudo? 
                      Vou mostrar Daily Check apenas se não tiver nada mais importante ou sempre, mas compactado.
                  */}
                  {events.filter((e) => e.audit_type === "DAILY_CHECK").length >
                    0 && (
                    <div className="text-[9px] text-slate-500 truncate px-1">
                      • Check Diário
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    );
  };

  const formatDate = (dateString) => {
    if (!dateString) return "N/A";
    try {
      // Tentar converter formato SQL (YYYY-MM-DD HH:MM:SS) para ISO
      const isoString = dateString.replace(" ", "T");
      const date = new Date(isoString);
      if (isNaN(date.getTime())) return "Data Inválida";
      return date.toLocaleDateString();
    } catch (e) {
      return "Erro Data";
    }
  };

  const renderPDCA = () => (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-lg">
        <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
          <Activity className="text-emerald-400" />
          Relatórios de Melhoria Contínua (PDCA)
          <span className="text-xs text-slate-500 ml-2 font-normal">
            ({Array.isArray(pdcaReports) ? pdcaReports.length : 0} relatórios
            encontrados)
          </span>
        </h3>
        <div className="space-y-4">
          {Array.isArray(pdcaReports) && pdcaReports.length > 0 ? (
            pdcaReports.map((report, index) => (
              <div
                key={report.id || index}
                className="bg-slate-900/50 p-4 rounded-lg border border-slate-700"
              >
                <div className="flex justify-between items-start mb-2">
                  <div>
                    <h4 className="text-lg font-semibold text-slate-200">
                      {report.cycle_period || "Período N/A"}
                    </h4>
                    <span className="text-xs text-emerald-400 font-mono">
                      Gerado em: {formatDate(report.generation_date)}
                    </span>
                  </div>
                  <a
                    href={`http://localhost:8080/api/v1/audit/reports/${report.id}/download`}
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center gap-2 px-3 py-1.5 bg-slate-700 hover:bg-slate-600 text-white rounded text-sm transition-colors"
                  >
                    <FileText size={16} />
                    Visualizar PDF
                  </a>
                </div>
                <p className="text-slate-400 text-sm mb-2 mt-2">
                  {report.summary || "Sem resumo disponível."}
                </p>

                {/* Seção de Melhoria Contínua */}
                <div className="bg-indigo-900/30 p-3 rounded border-l-2 border-indigo-500 mt-3">
                  <p className="text-xs font-bold text-indigo-300 mb-1 flex items-center gap-1">
                    <TrendingUp size={12} />
                    Sugestão de Melhoria:
                  </p>
                  <p className="text-xs text-slate-300 italic">
                    "
                    {report.improvement_suggestion ||
                      "Nenhuma sugestão registrada."}
                    "
                  </p>
                </div>

                <div className="flex gap-4 mt-3 pt-3 border-t border-slate-800">
                  <div className="text-xs text-slate-500">
                    Entregas:{" "}
                    <span className="text-slate-300">
                      {report.metrics_snapshot?.total_entregas || 0}
                    </span>
                  </div>
                  <div className="text-xs text-slate-500">
                    Bugs:{" "}
                    <span className="text-slate-300">
                      {report.metrics_snapshot?.bugs_encontrados || 0}
                    </span>
                  </div>
                </div>
              </div>
            ))
          ) : (
            <div className="text-center py-8 text-slate-500">
              <p>Nenhum relatório PDCA gerado ainda.</p>
              <p className="text-xs mt-2">
                Tente disparar uma auditoria manual para gerar dados.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <header className="mb-8">
        <h1 className="text-3xl font-bold text-white flex items-center gap-3">
          <ShieldCheck className="text-indigo-500" size={32} />
          Sala de Controle de Qualidade
        </h1>
        <p className="text-slate-400 mt-2">
          Monitoramento de conformidade, alertas de governança e auditoria
          contínua.
        </p>
      </header>

      {/* Tabs */}
      <div className="flex gap-4 mb-8 border-b border-slate-700">
        <button
          onClick={() => setActiveTab("dashboard")}
          className={`pb-4 px-2 text-sm font-medium transition-colors relative ${
            activeTab === "dashboard"
              ? "text-indigo-400"
              : "text-slate-400 hover:text-slate-200"
          }`}
        >
          Dashboard
          {activeTab === "dashboard" && (
            <div className="absolute bottom-0 left-0 w-full h-0.5 bg-indigo-500 rounded-t-full" />
          )}
        </button>
        <button
          onClick={() => setActiveTab("calendar")}
          className={`pb-4 px-2 text-sm font-medium transition-colors relative ${
            activeTab === "calendar"
              ? "text-indigo-400"
              : "text-slate-400 hover:text-slate-200"
          }`}
        >
          Calendário de Auditoria
          {activeTab === "calendar" && (
            <div className="absolute bottom-0 left-0 w-full h-0.5 bg-indigo-500 rounded-t-full" />
          )}
        </button>
        <button
          onClick={() => setActiveTab("pdca")}
          className={`pb-4 px-2 text-sm font-medium transition-colors relative ${
            activeTab === "pdca"
              ? "text-indigo-400"
              : "text-slate-400 hover:text-slate-200"
          }`}
        >
          Relatórios PDCA
          {activeTab === "pdca" && (
            <div className="absolute bottom-0 left-0 w-full h-0.5 bg-indigo-500 rounded-t-full" />
          )}
        </button>
      </div>

      {/* Content */}
      <div className="min-h-[500px]">
        {activeTab === "dashboard" && renderDashboard()}
        {activeTab === "calendar" && renderCalendar()}
        {activeTab === "pdca" && renderPDCA()}
      </div>
    </div>
  );
};

export default QualityControlRoom;
