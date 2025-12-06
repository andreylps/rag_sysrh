import React, { useState, useEffect } from "react";
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts";
import {
  LayoutDashboard,
  TrendingUp,
  AlertCircle,
  CheckCircle2,
  Clock,
  Users,
  Target,
  Briefcase,
  Activity,
  DollarSign,
  PieChart as PieChartIcon,
  BarChart2,
  Calendar,
  Filter,
  RefreshCw,
  Zap,
  Layers,
  ArrowUpRight,
  ArrowDownRight,
  HardDrive,
} from "lucide-react";
import { API_BASE_URL } from "../config";
import AnalysisTab from "../components/AnalysisTab";

// Cores do tema (Dark Mode)
const COLORS = {
  primary: "#818cf8", // Indigo-400
  secondary: "#a78bfa", // Violet-400
  success: "#34d399", // Emerald-400
  warning: "#fbbf24", // Amber-400
  danger: "#f87171", // Red-400
  info: "#22d3ee", // Cyan-400
  dark: "#0f172a", // Slate-900
  light: "#f8fafc", // Slate-50
  chart: [
    "#818cf8", // Indigo
    "#34d399", // Emerald
    "#fbbf24", // Amber
    "#f87171", // Red
    "#a78bfa", // Violet
    "#f472b6", // Pink
    "#22d3ee", // Cyan
    "#2dd4bf", // Teal
  ],
};

const Dashboard = () => {
  const [activeTab, setActiveTab] = useState("operations"); // operations | billing | analysis
  const [selectedPeriod, setSelectedPeriod] = useState("30");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdate, setLastUpdate] = useState(new Date());

  // Estado unificado para os dados de operações (7 painéis)
  const [opsData, setOpsData] = useState(null);

  // Estado para dados financeiros
  const [billingData, setBillingData] = useState(null);

  const fetchDashboardData = async () => {
    setLoading(true);
    setError(null);
    try {
      // 1. Fetch Operations Data
      const opsResponse = await fetch(
        `${API_BASE_URL}/dashboard/production?days=${selectedPeriod}`
      );
      if (!opsResponse.ok) throw new Error("Erro ao buscar dados de operação");
      const opsJson = await opsResponse.json();
      setOpsData(opsJson);

      // 2. Fetch Billing Data (Se necessário)
      if (activeTab === "billing" || activeTab === "analysis") {
        const billResponse = await fetch(
          `${API_BASE_URL}/dashboard/billing?days=${selectedPeriod}`
        );
        if (!billResponse.ok)
          throw new Error("Erro ao buscar dados financeiros");
        const billJson = await billResponse.json();
        setBillingData(billJson);
      }

      setLastUpdate(new Date());
    } catch (err) {
      console.error("Erro no dashboard:", err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, [activeTab, selectedPeriod]);

  // --- COMPONENTES DE UI (DARK MODE) ---

  const StatCard = ({
    title,
    value,
    subtext,
    icon: Icon,
    trend,
    color = "primary",
  }) => {
    // Mapeamento de cores para classes Tailwind (Dark Mode)
    const colorClasses = {
      blue: "bg-blue-900/30 text-blue-400 border-blue-800/50",
      green: "bg-emerald-900/30 text-emerald-400 border-emerald-800/50",
      violet: "bg-violet-900/30 text-violet-400 border-violet-800/50",
      orange: "bg-amber-900/30 text-amber-400 border-amber-800/50",
      red: "bg-red-900/30 text-red-400 border-red-800/50",
      primary: "bg-indigo-900/30 text-indigo-400 border-indigo-800/50",
    };

    const iconStyleClass = colorClasses[color] || colorClasses.primary;

    return (
      <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700 shadow-lg hover:bg-slate-800 transition-all duration-300">
        <div className="flex justify-between items-start mb-4">
          <div>
            <p className="text-sm font-medium text-slate-400 mb-1">{title}</p>
            <h3 className="text-2xl font-bold text-slate-100 tracking-tight">
              {value}
            </h3>
          </div>
          <div className={`p-3 rounded-lg border ${iconStyleClass}`}>
            <Icon size={20} />
          </div>
        </div>
        {(subtext || trend) && (
          <div className="flex items-center text-sm">
            {trend && (
              <span
                className={`flex items-center font-medium mr-2 ${
                  trend === "up" ? "text-emerald-400" : "text-red-400"
                }`}
              >
                {trend === "up" ? (
                  <ArrowUpRight size={16} />
                ) : (
                  <ArrowDownRight size={16} />
                )}
              </span>
            )}
            <span className="text-slate-500">{subtext}</span>
          </div>
        )}
      </div>
    );
  };

  const ChartCard = ({ title, children, action }) => (
    <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700 shadow-lg h-full flex flex-col transition-all duration-300 hover:bg-slate-800 min-w-0">
      <div className="flex justify-between items-center mb-6">
        <h3 className="text-lg font-semibold text-slate-200 flex items-center gap-2">
          {title}
        </h3>
        {action}
      </div>
      {/* Wrapper com altura fixa para garantir renderização do Recharts */}
      <div className="w-full h-[320px]">{children}</div>
    </div>
  );

  // --- RENDERIZAÇÃO DOS PAINÉIS ---

  const renderOperationsTab = () => {
    if (!opsData) return null;

    const {
      panel_demand = {},
      panel_effort = {},
      panel_delivery = {},
      panel_complexity = {},
      panel_flow = {},
      panel_strategic = {},
      panel_executive = {},
    } = opsData;

    return (
      <div className="space-y-8 animate-in fade-in duration-500">
        {/* 1. PAINEL EXECUTIVO (RESUMO) */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <StatCard
            title="Backlog Total"
            value={panel_executive.backlog_total || 0}
            subtext="Itens pendentes"
            icon={Layers}
            color="blue"
          />
          <StatCard
            title="Entregas (Mês)"
            value={panel_executive.deliveries_month || 0}
            subtext="Itens concluídos"
            icon={CheckCircle2}
            color="green"
            trend="up"
          />
          <StatCard
            title="Lead Time Médio"
            value={`${(panel_executive.lead_time_avg || 0).toFixed(1)} dias`}
            subtext="Tempo de ciclo"
            icon={Clock}
            color="violet"
          />
          <StatCard
            title="No Prazo"
            value={`${panel_executive.on_time_percent || 0}%`}
            subtext="SLA Compliance"
            icon={Target}
            color="orange"
          />
          <StatCard
            title="Esforço vs Cap."
            value={panel_executive.effort_vs_capacity || "0/0"}
            subtext="Horas utilizadas"
            icon={Zap}
            color="red"
          />
        </div>

        {/* 2. DEMANDA & ESFORÇO */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <ChartCard title="Classificação da Demanda (Por Tipo)">
            <ResponsiveContainer width="99%" height="100%">
              <BarChart
                data={panel_demand.by_type || []}
                layout="vertical"
                margin={{ left: 40, right: 20 }}
              >
                <CartesianGrid
                  strokeDasharray="3 3"
                  horizontal={true}
                  vertical={false}
                  stroke="#334155"
                />
                <XAxis type="number" stroke="#94a3b8" fontSize={12} />
                <YAxis
                  dataKey="name"
                  type="category"
                  width={100}
                  tick={{ fontSize: 12, fill: "#94a3b8" }}
                  stroke="#94a3b8"
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1e293b",
                    borderColor: "#334155",
                    color: "#f1f5f9",
                    borderRadius: "8px",
                  }}
                  cursor={{ fill: "#334155", opacity: 0.4 }}
                />
                <Bar
                  dataKey="value"
                  fill={COLORS.primary}
                  radius={[0, 4, 4, 0]}
                  barSize={24}
                />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title="Backlog por Time">
            <ResponsiveContainer width="99%" height="100%">
              <PieChart>
                <Pie
                  data={panel_demand.backlog_by_team || []}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={5}
                  dataKey="value"
                  stroke="none"
                >
                  {(panel_demand.backlog_by_team || []).map((entry, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={COLORS.chart[index % COLORS.chart.length]}
                    />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1e293b",
                    borderColor: "#334155",
                    color: "#f1f5f9",
                    borderRadius: "8px",
                  }}
                />
                <Legend
                  layout="vertical"
                  verticalAlign="middle"
                  align="right"
                  iconType="circle"
                  wrapperStyle={{ color: "#cbd5e1" }}
                />
              </PieChart>
            </ResponsiveContainer>
          </ChartCard>
        </div>

        {/* 3. ENTREGAS & COMPLEXIDADE */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2">
            <ChartCard title="Evolução de Entregas (Throughput)">
              <ResponsiveContainer width="99%" height="100%">
                <BarChart data={panel_delivery.throughput_history || []}>
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                    stroke="#334155"
                  />
                  <XAxis dataKey="name" stroke="#94a3b8" fontSize={12} />
                  <YAxis stroke="#94a3b8" fontSize={12} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: "#1e293b",
                      borderColor: "#334155",
                      color: "#f1f5f9",
                      borderRadius: "8px",
                    }}
                  />
                  <Bar
                    dataKey="value"
                    fill={COLORS.success}
                    radius={[4, 4, 0, 0]}
                    barSize={32}
                  />
                </BarChart>
              </ResponsiveContainer>
            </ChartCard>
          </div>

          <ChartCard title="Complexidade das Demandas">
            <ResponsiveContainer width="99%" height="100%">
              <PieChart>
                <Pie
                  data={panel_complexity.distribution || []}
                  cx="50%"
                  cy="50%"
                  innerRadius={0}
                  outerRadius={100}
                  dataKey="value"
                  stroke="none"
                >
                  {(panel_complexity.distribution || []).map((entry, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={
                        entry.name === "Alta"
                          ? COLORS.danger
                          : entry.name === "Média"
                          ? COLORS.warning
                          : COLORS.success
                      }
                    />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1e293b",
                    borderColor: "#334155",
                    color: "#f1f5f9",
                    borderRadius: "8px",
                  }}
                />
                <Legend
                  verticalAlign="bottom"
                  height={36}
                  iconType="circle"
                  wrapperStyle={{ color: "#cbd5e1" }}
                />
              </PieChart>
            </ResponsiveContainer>
          </ChartCard>
        </div>

        {/* 4. FLUXO & ESTRATÉGICO */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700 shadow-lg">
            <h3 className="text-lg font-semibold text-slate-200 mb-4 flex items-center gap-2">
              <Activity size={20} className="text-indigo-400" /> Fluxo (Kanban)
            </h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center p-3 bg-slate-900/50 rounded-lg border border-slate-700/50">
                <span className="text-slate-400">Work In Progress (WIP)</span>
                <span className="font-bold text-slate-200">
                  {panel_flow.wip || 0}
                </span>
              </div>
              <div className="flex justify-between items-center p-3 bg-slate-900/50 rounded-lg border border-slate-700/50">
                <span className="text-slate-400">Cycle Time Médio</span>
                <span className="font-bold text-slate-200">
                  {(panel_flow.cycle_time_avg || 0).toFixed(1)} dias
                </span>
              </div>
              <div className="flex justify-between items-center p-3 bg-slate-900/50 rounded-lg border border-slate-700/50">
                <span className="text-slate-400">Eficiência de Fluxo</span>
                <span className="font-bold text-slate-200">
                  {panel_flow.efficiency || 0}%
                </span>
              </div>
            </div>
          </div>

          <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700 shadow-lg">
            <h3 className="text-lg font-semibold text-slate-200 mb-4 flex items-center gap-2">
              <DollarSign size={20} className="text-emerald-400" /> Estratégico
            </h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center p-3 bg-slate-900/50 rounded-lg border border-slate-700/50">
                <span className="text-slate-400">Custo Estimado Total</span>
                <span className="font-bold text-slate-200">
                  R${" "}
                  {(panel_strategic.total_estimated_cost || 0).toLocaleString(
                    "pt-BR",
                    { maximumFractionDigits: 0 }
                  )}
                </span>
              </div>
              <div className="flex justify-between items-center p-3 bg-slate-900/50 rounded-lg border border-slate-700/50">
                <span className="text-slate-400">ROI (Estimado)</span>
                <span className="font-bold text-emerald-400">
                  R${" "}
                  {(panel_strategic.roi_proxy || 0).toLocaleString("pt-BR", {
                    maximumFractionDigits: 0,
                  })}
                </span>
              </div>
              <div className="flex justify-between items-center p-3 bg-red-900/20 rounded-lg border border-red-900/30">
                <span className="text-red-400">Itens em Risco</span>
                <span className="font-bold text-red-400">
                  {panel_strategic.items_at_risk || 0}
                </span>
              </div>
            </div>
          </div>

          <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700 shadow-lg">
            <h3 className="text-lg font-semibold text-slate-200 mb-4 flex items-center gap-2">
              <Users size={20} className="text-violet-400" /> Demanda por Área
            </h3>
            <div className="space-y-3">
              {(panel_demand.by_area || []).slice(0, 5).map((area, idx) => (
                <div key={idx} className="flex items-center justify-between">
                  <span className="text-sm text-slate-400 truncate max-w-[150px]">
                    {area.name}
                  </span>
                  <div className="flex items-center gap-2">
                    <div className="w-24 h-2 bg-slate-700 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-violet-500 rounded-full"
                        style={{
                          width: `${
                            (area.value / (panel_demand.total || 1)) * 100
                          }%`,
                        }}
                      />
                    </div>
                    <span className="text-xs font-medium text-slate-300 w-8 text-right">
                      {area.value}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  };

  const renderBillingTab = () => {
    if (!billingData)
      return (
        <div className="p-8 text-center text-slate-500">
          Carregando dados financeiros...
        </div>
      );

    const {
      panel_executive = {},
      panel_productivity = {},
      panel_costs = {},
      panel_risks = {},
    } = billingData;

    return (
      <div className="space-y-8 animate-in fade-in duration-500">
        {/* 1. PAINEL EXECUTIVO FINANCEIRO */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            title="Faturamento Total"
            value={`R$ ${(panel_executive.total_revenue || 0).toLocaleString(
              "pt-BR",
              { maximumFractionDigits: 0 }
            )}`}
            subtext="Receita Bruta"
            icon={DollarSign}
            color="green"
            trend="up"
          />
          <StatCard
            title="Margem Líquida"
            value={`R$ ${(panel_executive.net_margin || 0).toLocaleString(
              "pt-BR",
              { maximumFractionDigits: 0 }
            )}`}
            subtext="Resultado Final"
            icon={TrendingUp}
            color="blue"
          />
          <StatCard
            title="Ticket Médio"
            value={`R$ ${(panel_executive.ticket_avg || 0).toLocaleString(
              "pt-BR",
              { maximumFractionDigits: 0 }
            )}`}
            subtext="Por Demanda"
            icon={Target}
            color="violet"
          />
          <StatCard
            title="Margem Bruta (Est.)"
            value={`R$ ${(panel_executive.gross_margin || 0).toLocaleString(
              "pt-BR",
              { maximumFractionDigits: 0 }
            )}`}
            subtext="Antes de impostos"
            icon={Briefcase}
            color="orange"
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <ChartCard title="Top Clientes (Receita)">
            <ResponsiveContainer width="99%" height="100%">
              <BarChart
                data={panel_executive.top_clients || []}
                layout="vertical"
                margin={{ left: 40, right: 20 }}
              >
                <CartesianGrid
                  strokeDasharray="3 3"
                  horizontal={true}
                  vertical={false}
                  stroke="#334155"
                />
                <XAxis type="number" hide />
                <YAxis
                  dataKey="name"
                  type="category"
                  width={100}
                  tick={{ fontSize: 12, fill: "#94a3b8" }}
                  stroke="#94a3b8"
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1e293b",
                    borderColor: "#334155",
                    color: "#f1f5f9",
                    borderRadius: "8px",
                  }}
                />
                <Bar
                  dataKey="value"
                  fill={COLORS.success}
                  radius={[0, 4, 4, 0]}
                  barSize={24}
                />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title="Receita vs Meta (Mock)">
            <ResponsiveContainer width="99%" height="100%">
              <BarChart data={panel_executive.revenue_vs_target || []}>
                <CartesianGrid
                  strokeDasharray="3 3"
                  vertical={false}
                  stroke="#334155"
                />
                <XAxis dataKey="name" stroke="#94a3b8" fontSize={12} />
                <YAxis stroke="#94a3b8" fontSize={12} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1e293b",
                    borderColor: "#334155",
                    color: "#f1f5f9",
                    borderRadius: "8px",
                  }}
                />
                <Bar
                  dataKey="value"
                  fill={COLORS.primary}
                  radius={[4, 4, 0, 0]}
                  barSize={48}
                />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>
        </div>

        {/* 2. PRODUTIVIDADE X FINANCEIRO */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700 shadow-lg">
            <h3 className="text-lg font-semibold text-slate-200 mb-4 flex items-center gap-2">
              <Zap size={20} className="text-amber-400" /> Eficiência
            </h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center p-3 bg-slate-900/50 rounded-lg border border-slate-700/50">
                <span className="text-slate-400">Valor / Sprint (Mês)</span>
                <span className="font-bold text-slate-200">
                  R${" "}
                  {(panel_productivity.value_per_sprint || 0).toLocaleString(
                    "pt-BR",
                    { maximumFractionDigits: 0 }
                  )}
                </span>
              </div>
              <div className="flex justify-between items-center p-3 bg-slate-900/50 rounded-lg border border-slate-700/50">
                <span className="text-slate-400">Valor / Desenvolvedor</span>
                <span className="font-bold text-slate-200">
                  R${" "}
                  {(panel_productivity.value_per_dev || 0).toLocaleString(
                    "pt-BR",
                    { maximumFractionDigits: 0 }
                  )}
                </span>
              </div>
              <div className="flex justify-between items-center p-3 bg-slate-900/50 rounded-lg border border-slate-700/50">
                <span className="text-slate-400">Taxa de Conversão</span>
                <span className="font-bold text-emerald-400">
                  {panel_productivity.conversion_rate || 0}%
                </span>
              </div>
            </div>
          </div>

          <div className="md:col-span-2">
            <ChartCard title="Custo vs Margem por Time">
              <ResponsiveContainer width="99%" height="100%">
                <BarChart data={panel_productivity.cost_vs_margin || []}>
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                    stroke="#334155"
                  />
                  <XAxis dataKey="name" stroke="#94a3b8" fontSize={12} />
                  <YAxis stroke="#94a3b8" fontSize={12} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: "#1e293b",
                      borderColor: "#334155",
                      color: "#f1f5f9",
                      borderRadius: "8px",
                    }}
                  />
                  <Legend wrapperStyle={{ color: "#cbd5e1" }} />
                  <Bar
                    dataKey="cost"
                    name="Custo"
                    fill={COLORS.danger}
                    radius={[4, 4, 0, 0]}
                  />
                  <Bar
                    dataKey="margin"
                    name="Margem"
                    fill={COLORS.success}
                    radius={[4, 4, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            </ChartCard>
          </div>
        </div>

        {/* 3. CUSTOS E RISCOS */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700 shadow-lg">
            <h3 className="text-lg font-semibold text-slate-200 mb-4 flex items-center gap-2">
              <Activity size={20} className="text-red-400" /> Custos
              Operacionais
            </h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="p-4 bg-slate-900/50 rounded-lg border border-slate-700/50 text-center">
                <p className="text-xs text-slate-500 uppercase">
                  Custo / Demanda
                </p>
                <p className="text-xl font-bold text-slate-200 mt-1">
                  R${" "}
                  {(panel_costs.cost_per_demand || 0).toLocaleString("pt-BR", {
                    maximumFractionDigits: 0,
                  })}
                </p>
              </div>
              <div className="p-4 bg-slate-900/50 rounded-lg border border-slate-700/50 text-center">
                <p className="text-xs text-slate-500 uppercase">Custo / Hora</p>
                <p className="text-xl font-bold text-slate-200 mt-1">
                  R$ {(panel_costs.cost_per_hour || 0).toFixed(2)}
                </p>
              </div>
              <div className="p-4 bg-slate-900/50 rounded-lg border border-slate-700/50 text-center">
                <p className="text-xs text-slate-500 uppercase">
                  Custo Retrabalho
                </p>
                <p className="text-xl font-bold text-red-400 mt-1">
                  R${" "}
                  {(panel_costs.rework_cost || 0).toLocaleString("pt-BR", {
                    maximumFractionDigits: 0,
                  })}
                </p>
              </div>
              <div className="p-4 bg-slate-900/50 rounded-lg border border-slate-700/50 text-center">
                <p className="text-xs text-slate-500 uppercase">
                  Desvio Financeiro
                </p>
                <p className="text-xl font-bold text-amber-400 mt-1">
                  R${" "}
                  {(panel_costs.financial_deviation || 0).toLocaleString(
                    "pt-BR",
                    { maximumFractionDigits: 0 }
                  )}
                </p>
              </div>
            </div>
          </div>

          <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700 shadow-lg">
            <h3 className="text-lg font-semibold text-slate-200 mb-4 flex items-center gap-2">
              <AlertCircle size={20} className="text-orange-400" /> Riscos
              Financeiros
            </h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-slate-400">
                  Concentração de Receita (Top 1)
                </span>
                <span
                  className={`font-bold ${
                    (panel_risks.concentration_pct || 0) > 50
                      ? "text-red-400"
                      : "text-slate-200"
                  }`}
                >
                  {(panel_risks.concentration_pct || 0).toFixed(1)}%
                </span>
              </div>
              <div className="w-full bg-slate-700 rounded-full h-2.5">
                <div
                  className="bg-orange-500 h-2.5 rounded-full"
                  style={{
                    width: `${Math.min(
                      panel_risks.concentration_pct || 0,
                      100
                    )}%`,
                  }}
                ></div>
              </div>

              <div className="pt-4 border-t border-slate-700">
                <p className="text-sm text-slate-400 mb-2">
                  Projetos com Menor Margem:
                </p>
                <div className="space-y-2">
                  {(panel_risks.negative_projects || [])
                    .slice(0, 3)
                    .map((proj, idx) => (
                      <div key={idx} className="flex justify-between text-sm">
                        <span className="text-slate-300">{proj.name}</span>
                        <span className="text-red-400 font-medium">
                          R${" "}
                          {proj.margin.toLocaleString("pt-BR", {
                            maximumFractionDigits: 0,
                          })}
                        </span>
                      </div>
                    ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-slate-900 p-6 space-y-8">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-100 tracking-tight">
            Dashboard de Operações
          </h1>
          <p className="text-slate-400 mt-1">
            Visão unificada de demanda, entregas e performance.
          </p>
        </div>

        <div className="flex items-center gap-3 bg-slate-800 p-1.5 rounded-lg border border-slate-700 shadow-sm">
          {["operations", "billing", "analysis"].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 rounded-md text-sm font-medium transition-all ${
                activeTab === tab
                  ? "bg-indigo-900/50 text-indigo-300 shadow-sm border border-indigo-700/50"
                  : "text-slate-400 hover:bg-slate-700 hover:text-slate-200"
              }`}
            >
              {tab === "operations"
                ? "Operação"
                : tab === "billing"
                ? "Financeiro"
                : "Análise IA"}
            </button>
          ))}
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center justify-between gap-4 bg-slate-800 p-4 rounded-xl border border-slate-700 shadow-lg">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 text-slate-400">
            <Filter size={18} />
            <span className="text-sm font-medium">Filtros:</span>
          </div>
          <select
            value={selectedPeriod}
            onChange={(e) => setSelectedPeriod(e.target.value)}
            className="bg-slate-900 border border-slate-700 text-sm font-medium text-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500 cursor-pointer py-2 pl-3 pr-8 outline-none"
          >
            <option value="7">Últimos 7 dias</option>
            <option value="30">Últimos 30 dias</option>
            <option value="90">Último Trimestre</option>
            <option value="year">Este Ano</option>
          </select>
        </div>

        <div className="flex items-center gap-3">
          <span className="text-xs text-slate-500 flex items-center gap-1">
            <Clock size={14} />
            Atualizado: {lastUpdate.toLocaleTimeString()}
          </span>
          <button
            onClick={fetchDashboardData}
            className="p-2 text-slate-400 hover:text-indigo-400 hover:bg-slate-700 rounded-full transition-colors"
            title="Atualizar dados"
          >
            <RefreshCw size={18} className={loading ? "animate-spin" : ""} />
          </button>
        </div>
      </div>

      {/* Content */}
      {loading && !opsData ? (
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500"></div>
        </div>
      ) : error ? (
        <div className="bg-red-900/20 border border-red-900/50 text-red-400 p-4 rounded-lg flex items-center gap-3">
          <AlertCircle size={20} />
          <p>{error}</p>
        </div>
      ) : (
        <>
          {/* WIDGET DE SAÚDE DO SISTEMA */}

          {activeTab === "operations" && renderOperationsTab()}
          {activeTab === "billing" && renderBillingTab()}
          {activeTab === "analysis" && (
            <AnalysisTab
              API_BASE_URL={API_BASE_URL}
              selectedPeriod={selectedPeriod}
            />
          )}
        </>
      )}
    </div>
  );
};

export default Dashboard;
