import React, { useState, useEffect, useCallback } from "react";
import {
  TrendingUp,
  TrendingDown,
  Activity,
  AlertCircle,
  RefreshCw,
  Filter,
  BarChart3,
  Brain,
  DollarSign,
  XCircle,
  Clock,
  Check,
} from "lucide-react";
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
  Area,
  AreaChart,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts";
import OperationalOverview from "../components/OperationalOverview"; // Importação Segura

// --- Componentes Utilitários (Gauge e MetricCard) ---
// (Mantidos exatamente iguais. Sem alterações necessárias aqui.)
const GaugeChart = ({ value, max = 100, title, color }) => {
  const percentage = (value / max) * 100;
  const rotation = (percentage / 100) * 180 - 90;
  const getColor = (val) => {
    if (val >= 100) return "#10b981";
    if (val >= 50) return "#10b981";
    return "#ef4444";
  };
  const gaugeColor = color || getColor(value);
  return (
    <div className="flex flex-col items-center justify-center h-full">
      <div className="relative w-40 h-20 overflow-hidden">
        <svg viewBox="0 0 200 100" className="w-full h-full">
          <path
            d="M 20 90 A 80 80 0 0 1 180 90"
            fill="none"
            stroke="#1e293b"
            strokeWidth="20"
            strokeLinecap="round"
          />
          <path
            d="M 20 90 A 80 80 0 0 1 180 90"
            fill="none"
            stroke={gaugeColor}
            strokeWidth="20"
            strokeLinecap="round"
            strokeDasharray={`${percentage * 2.51} 251`}
          />
          <circle cx="100" cy="90" r="6" fill="#94a3b8" />
          <line
            x1="100"
            y1="90"
            x2="100"
            y2="30"
            stroke="#f8fafc"
            strokeWidth="3"
            strokeLinecap="round"
            transform={`rotate(${rotation} 100 90)`}
          />
        </svg>
        <div className="absolute inset-0 flex items-end justify-center pb-2">
          <span className="text-2xl font-bold" style={{ color: gaugeColor }}>
            {/* Adicionado verificação para evitar erro se value for nulo/indefinido antes dos dados chegarem */}
            {value?.toFixed(2)}%
          </span>
        </div>
      </div>
      <span className="text-xs text-slate-400 mt-2">{title}</span>
    </div>
  );
};

const MetricCard = ({
  title,
  value,
  unit,
  change,
  trend,
  icon: Icon,
  colorFrom = "from-cyan-600",
  colorTo = "to-cyan-700",
  iconColor = "text-cyan-200",
  textColor = "text-cyan-100",
}) => (
  <div
    className={`bg-gradient-to-br ${colorFrom} ${colorTo} rounded-lg p-4 shadow-lg`}
  >
    <div className="flex items-start justify-between mb-2">
      <span className={`text-sm ${textColor}`}>{title}</span>
      {Icon && <Icon className={`w-5 h-5 ${iconColor}`} />}
    </div>
    <div className="flex items-baseline gap-2">
      <span className="text-3xl font-bold text-white">{value}</span>
      <span className={`text-lg ${textColor}`}>{unit}</span>
    </div>
    {change && (
      <div className="flex items-center gap-1 mt-2">
        {trend === "up" ? (
          <TrendingUp className="w-4 h-4 text-green-300" />
        ) : (
          <TrendingDown className="w-4 h-4 text-red-300" />
        )}
        <span
          className={`text-sm ${
            trend === "up" ? "text-green-300" : "text-red-300"
          }`}
        >
          {change}
        </span>
      </div>
    )}
  </div>
);

// --- Conteúdo das Abas (Produção, Faturamento, IA) ---
// (Estes componentes são apenas para exibição e não mudam. Eles recebem os dados e os mostram.)
const ProductionContent = ({ data }) => (
  <div className="grid grid-cols-12 gap-4">
    <div className="col-span-3 bg-slate-900 rounded-lg p-6 border border-slate-800">
      <div className="mb-4">
        <h2 className="text-lg font-semibold text-white mb-1">OEE</h2>
        <p className="text-xs text-slate-400">
          Overall Equipment Effectiveness
        </p>
      </div>
      <div className="relative mb-6 h-32">
        <svg viewBox="0 0 200 120" className="w-full h-full">
          <defs>
            <linearGradient id="oeeGradient" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="#10b981" />
              <stop offset="100%" stopColor="#059669" />
            </linearGradient>
          </defs>
          <path
            d="M 20 100 A 80 80 0 0 1 180 100"
            fill="none"
            stroke="#1e293b"
            strokeWidth="20"
            strokeLinecap="round"
          />
          <path
            d="M 20 100 A 80 80 0 0 1 180 100"
            fill="none"
            stroke={data.oee >= 50 ? "url(#oeeGradient)" : "#ef4444"}
            strokeWidth="20"
            strokeLinecap="round"
            strokeDasharray={`${data.oee * 2.51} 251`}
          />
        </svg>
        <div className="absolute inset-0 flex items-center justify-center pt-6">
          <span
            className="text-2xl font-bold"
            style={{ color: data.oee >= 50 ? "#10b981" : "#ef4444" }}
          >
            {data.oee?.toFixed(2)}%
          </span>
        </div>
      </div>
      <div className="flex justify-between text-xs text-slate-500 mb-6">
        <span>0,00%</span>
        <span>100,00%</span>
      </div>
      <ResponsiveContainer width="100%" height={60}>
        <AreaChart data={data.oeeHistory}>
          <defs>
            <linearGradient id="areaGradient" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#06b6d4" stopOpacity={0.3} />
              <stop offset="95%" stopColor="#06b6d4" stopOpacity={0} />
            </linearGradient>
          </defs>
          <Area
            type="monotone"
            dataKey="value"
            stroke="#06b6d4"
            fill="url(#areaGradient)"
            strokeWidth={2}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
    <div className="col-span-6 grid grid-cols-3 gap-4">
      <div className="bg-slate-900 rounded-lg p-4 border border-slate-800">
        <div className="mb-2">
          <h3 className="text-sm font-semibold text-white">Disponibilidade</h3>
        </div>
        <GaugeChart value={data.availability} title="" color="#f97316" />
        <ResponsiveContainer width="100%" height={50}>
          <AreaChart data={data.availabilityHistory || []}>
            <Area
              type="monotone"
              dataKey="v"
              stroke="#f97316"
              fill="#f9731633"
              strokeWidth={1.5}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
      <div className="bg-slate-900 rounded-lg p-4 border border-slate-800">
        <div className="mb-2">
          <h3 className="text-sm font-semibold text-white">Performance</h3>
        </div>
        <GaugeChart value={data.performance} title="" color="#3b82f6" />
        <ResponsiveContainer width="100%" height={50}>
          <AreaChart data={data.performanceHistory || []}>
            <Area
              type="monotone"
              dataKey="v"
              stroke="#3b82f6"
              fill="#3b82f633"
              strokeWidth={1.5}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
      <div className="bg-slate-900 rounded-lg p-4 border border-slate-800">
        <div className="mb-2">
          <h3 className="text-sm font-semibold text-white">Qualidade</h3>
        </div>
        <GaugeChart value={data.quality} title="" color="#f97316" />
        <ResponsiveContainer width="100%" height={50}>
          <AreaChart data={data.qualityHistory || []}>
            <Area
              type="monotone"
              dataKey="v"
              stroke="#f97316"
              fill="#f9731633"
              strokeWidth={1.5}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
    <div className="col-span-3 grid grid-cols-1 gap-4">
      <MetricCard
        title="Qtd Planejada"
        value={data.qtdPlanejada}
        unit={data.qtdPlanejadaUnit}
        icon={Activity}
      />
      <MetricCard
        title="Qtd Produzida"
        value={data.qtdProduzida}
        unit={data.qtdProduzidaUnit}
        trend={data.qtdProduzidaTrend}
        change={data.qtdProduzidaChange}
      />
      <MetricCard
        title="Qtd Rejeitada"
        value={data.qtdRejeitada}
        unit={data.qtdRejeitadaUnit}
        trend={data.qtdRejeitadaTrend}
        change={data.qtdRejeitadaChange}
        icon={AlertCircle}
      />
    </div>
    <div className="col-span-9 bg-slate-900 rounded-lg p-6 border border-slate-800">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h3 className="text-lg font-semibold text-white">
            Produção ao longo do tempo
          </h3>
        </div>
      </div>
      <ResponsiveContainer width="100%" height={280}>
        <AreaChart data={data.productionOverTime}>
          <CartesianGrid
            strokeDasharray="3 3"
            stroke="#334155"
            vertical={false}
          />
          <XAxis dataKey="month" stroke="#64748b" fontSize={11} />
          <YAxis stroke="#64748b" fontSize={11} />
          <Tooltip
            contentStyle={{
              backgroundColor: "#1e293b",
              border: "1px solid #334155",
              borderRadius: "8px",
            }}
            labelStyle={{ color: "#f8fafc" }}
          />
          <Area
            type="monotone"
            dataKey="value"
            stroke="#f8fafc"
            fill="#f8fafc"
            fillOpacity={0.8}
            strokeWidth={2}
          />
          <Line
            type="monotone"
            dataKey="target"
            stroke="#64748b"
            strokeWidth={2}
            strokeDasharray="5 5"
            dot={false}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
    <div className="col-span-3 bg-slate-900 rounded-lg p-6 border border-slate-800">
      <h3 className="text-lg font-semibold text-white mb-4">
        Ranking Rejeições
      </h3>
      <div className="space-y-3 max-h-80 overflow-y-auto">
        {data.rejectionRanking.map((item, index) => (
          <div key={index} className="flex items-center gap-3">
            <div className="flex-1">
              <div className="flex items-center justify-between mb-1">
                <span className="text-xs text-slate-300">{item.name}</span>
                <span className="text-xs font-semibold text-white">
                  {item.formattedValue}
                </span>
              </div>
              <div className="h-6 bg-slate-800 rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-orange-500 to-orange-600 flex items-center justify-end pr-2"
                  style={{ width: `${item.percentage}%` }}
                ></div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
    <div className="col-span-9 bg-slate-900 rounded-lg p-6 border border-slate-800">
      <h3 className="text-lg font-semibold text-white mb-4">
        Ranking Ocorrências
      </h3>
      <ResponsiveContainer width="100%" height={250}>
        <BarChart data={data.occurrencesRanking} layout="vertical">
          <CartesianGrid
            strokeDasharray="3 3"
            stroke="#334155"
            horizontal={false}
          />
          <XAxis type="number" stroke="#64748b" fontSize={11} />
          <YAxis
            dataKey="name"
            type="category"
            stroke="#64748b"
            fontSize={11}
            width={150}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: "#1e293b",
              border: "1px solid #334155",
              borderRadius: "8px",
            }}
            labelStyle={{ color: "#f8fafc" }}
          />
          <Bar dataKey="value" fill="#f97316" radius={[0, 8, 8, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  </div>
);

const FaturamentoContent = ({ data }) => (
  <div className="grid grid-cols-12 gap-4">
    <div className="col-span-4 grid grid-cols-1 gap-4">
      <MetricCard
        title="Receita Total"
        value={data.receitaTotal}
        unit={data.receitaTotalUnit}
        icon={DollarSign}
        trend={data.receitaTotalTrend}
        change={data.receitaTotalChange}
        colorFrom="from-emerald-600"
        colorTo="to-emerald-700"
        iconColor="text-emerald-200"
        textColor="text-emerald-100"
      />
      <MetricCard
        title="Custo Operacional"
        value={data.custoOperacional}
        unit={data.custoOperacionalUnit}
        icon={Activity}
        trend={data.custoOperacionalTrend}
        change={data.custoOperacionalChange}
        colorFrom="from-rose-600"
        colorTo="to-rose-700"
        iconColor="text-rose-200"
        textColor="text-rose-100"
      />
      <MetricCard
        title="Lucro Líquido"
        value={data.lucroLiquido}
        unit={data.lucroLiquidoUnit}
        icon={TrendingUp}
        trend={data.lucroLiquidoTrend}
        change={data.lucroLiquidoChange}
        colorFrom="from-blue-600"
        colorTo="to-blue-700"
        iconColor="text-blue-200"
        textColor="text-blue-100"
      />
    </div>
    <div className="col-span-8 bg-slate-900 rounded-lg p-6 border border-slate-800">
      <h3 className="text-lg font-semibold text-white mb-4">
        Evolução Financeira
      </h3>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={data.evolucaoFinanceira}>
          <CartesianGrid
            strokeDasharray="3 3"
            stroke="#334155"
            vertical={false}
          />
          <XAxis dataKey="month" stroke="#64748b" fontSize={11} />
          <YAxis stroke="#64748b" fontSize={11} />
          <Tooltip
            contentStyle={{
              backgroundColor: "#1e293b",
              border: "1px solid #334155",
              borderRadius: "8px",
            }}
            labelStyle={{ color: "#f8fafc" }}
          />
          <Legend wrapperStyle={{ paddingTop: "10px" }} />
          <Bar
            dataKey="receita"
            name="Receita"
            fill="#10b981"
            radius={[4, 4, 0, 0]}
          />
          <Bar
            dataKey="custo"
            name="Custo"
            fill="#ef4444"
            radius={[4, 4, 0, 0]}
          />
          <Bar
            dataKey="lucro"
            name="Lucro"
            fill="#3b82f6"
            radius={[4, 4, 0, 0]}
          />
        </BarChart>
      </ResponsiveContainer>
    </div>
    <div className="col-span-5 bg-slate-900 rounded-lg p-6 border border-slate-800">
      <h3 className="text-lg font-semibold text-white mb-4">
        Composição de Custos
      </h3>
      <ResponsiveContainer width="100%" height={250}>
        <PieChart>
          <Pie
            data={data.composicaoCustos}
            cx="50%"
            cy="50%"
            innerRadius={60}
            outerRadius={80}
            fill="#8884d8"
            paddingAngle={5}
            dataKey="value"
            nameKey="name"
            label
          >
            {data.composicaoCustos.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color} />
            ))}
          </Pie>
          <Tooltip
            contentStyle={{
              backgroundColor: "#1e293b",
              border: "1px solid #334155",
              borderRadius: "8px",
            }}
            itemStyle={{ color: "#f8fafc" }}
          />
          <Legend layout="vertical" align="right" verticalAlign="middle" />
        </PieChart>
      </ResponsiveContainer>
    </div>
    <div className="col-span-7 bg-slate-900 rounded-lg p-6 border border-slate-800">
      <h3 className="text-lg font-semibold text-white mb-4">
        Top Clientes por Receita
      </h3>
      <div className="space-y-4">
        {data.topClientes.map((cliente, index) => (
          <div
            key={index}
            className="flex items-center justify-between border-b border-slate-800 pb-2"
          >
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-slate-800 rounded-full flex items-center justify-center font-bold text-slate-300">
                {index + 1}
              </div>
              <span className="text-slate-200 font-medium">{cliente.name}</span>
            </div>
            <span className="text-emerald-400 font-bold">
              {cliente.formattedValue}
            </span>
          </div>
        ))}
      </div>
    </div>
  </div>
);

const AnaliseIAContent = ({ data }) => (
  <div className="grid grid-cols-12 gap-4">
    <div className="col-span-8 bg-slate-900 rounded-lg p-8 border border-slate-800">
      <div className="flex items-center gap-3 mb-6">
        <Brain className="w-8 h-8 text-purple-400" />
        <h2 className="text-2xl font-bold text-white">
          Relatório de Inteligência Artificial
        </h2>
      </div>
      <div className="prose prose-invert max-w-none">
        <h3 className="text-xl font-semibold text-purple-300 mb-3">
          Resumo Executivo
        </h3>
        <p className="text-slate-300 leading-relaxed mb-6">{data.resumo}</p>
        <h3 className="text-xl font-semibold text-blue-300 mb-3">
          Análise de Produção
        </h3>
        <ul className="list-disc pl-5 space-y-2 text-slate-300 mb-6">
          {data.analiseProducao.pontosFortes.map((ponto, i) => (
            <li key={i} className="marker:text-green-400">
              <span className="font-semibold text-green-400">Ponto Forte:</span>{" "}
              {ponto}
            </li>
          ))}
          {data.analiseProducao.atencao.map((ponto, i) => (
            <li key={i} className="marker:text-yellow-400">
              <span className="font-semibold text-yellow-400">Atenção:</span>{" "}
              {ponto}
            </li>
          ))}
        </ul>
        <h3 className="text-xl font-semibold text-emerald-300 mb-3">
          Análise Financeira
        </h3>
        <ul className="list-disc pl-5 space-y-2 text-slate-300 mb-6">
          {data.analiseFinanceira.insights.map((insight, i) => (
            <li key={i}>
              <span className="font-semibold text-emerald-400">Insight:</span>{" "}
              {insight}
            </li>
          ))}
        </ul>
        <h3 className="text-xl font-semibold text-red-300 mb-3">
          Recomendações Estratégicas
        </h3>
        <div className="space-y-4">
          {data.recomendacoes.map((rec, i) => (
            <div
              key={i}
              className="bg-slate-800/50 p-4 rounded-lg border-l-4 border-purple-500"
            >
              <h4 className="font-semibold text-white mb-1">{rec.titulo}</h4>
              <p className="text-sm text-slate-400">{rec.descricao}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
    <div className="col-span-4 space-y-4">
      <div className="bg-slate-900 rounded-lg p-6 border border-slate-800">
        <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
          <AlertCircle className="w-5 h-5 text-yellow-400" />
          Alertas Críticos
        </h3>
        <div className="space-y-3">
          {data.alertas.map((alerta, i) => (
            <div
              key={i}
              className="flex items-start gap-3 bg-slate-800 p-3 rounded-md"
            >
              {alerta.tipo === "erro" ? (
                <XCircle className="w-5 h-5 text-red-400 mt-0.5" />
              ) : (
                <Clock className="w-5 h-5 text-yellow-400 mt-0.5" />
              )}
              <div>
                <p className="text-sm font-medium text-white">
                  {alerta.titulo}
                </p>
                <p className="text-xs text-slate-400">{alerta.descricao}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
      <div className="bg-slate-900 rounded-lg p-6 border border-slate-800 bg-gradient-to-br from-slate-900 to-purple-900/30">
        <h3 className="text-lg font-semibold text-white mb-2 flex items-center gap-2">
          <Brain className="w-5 h-5 text-purple-300" />
          Previsão de IA
        </h3>
        <p className="text-sm text-slate-300 mb-4">
          Com base nos dados atuais, a IA projeta para o próximo mês:
        </p>
        <div className="space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-sm text-slate-400">
              {data.previsao.metrica1Label}
            </span>
            <span className="text-lg font-bold text-green-400">
              {data.previsao.metrica1Value}
            </span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-slate-400">
              {data.previsao.metrica2Label}
            </span>
            <span className="text-lg font-bold text-emerald-400">
              {data.previsao.metrica2Value}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
);

// --- Componente Principal do Dashboard ---
const Dashboard = () => {
  // Estados para os dados de cada aba
  const [producaoData, setProducaoData] = useState(null);
  const [faturamentoData, setFaturamentoData] = useState(null);
  const [analiseIaData, setAnaliseIaData] = useState(null);

  // Estados de controle da interface
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null); // Novo estado de erro
  const [activeTab, setActiveTab] = useState("producao");
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [selectedPeriod, setSelectedPeriod] = useState("Últimos 30 dias");

  const periodOptions = [
    "Hoje",
    "Últimos 7 dias",
    "Últimos 30 dias",
    "Este Mês",
    "Último Trimestre",
  ];

  // Função principal para buscar os dados reais da API
  const fetchDashboardData = useCallback(async (period) => {
    setLoading(true);
    setError(null); // Limpa erro anterior
    try {
      console.log("Iniciando fetchDashboardData para o período:", period);

      // 1. Chamada para Dados de Produção
      const prodResponse = await fetch(
        `http://127.0.0.1:8080/api/v1/dashboard/production?period=${period}`
      );
      if (!prodResponse.ok) {
        throw new Error(
          `Erro API Produção: ${prodResponse.status} ${prodResponse.statusText}`
        );
      }
      const prodData = await prodResponse.json();
      setProducaoData(prodData);

      // 2. Chamada para Dados de Faturamento
      const billingResponse = await fetch(
        `http://127.0.0.1:8080/api/v1/dashboard/billing?period=${period}`
      );
      if (!billingResponse.ok) {
        throw new Error(
          `Erro API Faturamento: ${billingResponse.status} ${billingResponse.statusText}`
        );
      }
      const billingData = await billingResponse.json();
      setFaturamentoData(billingData);

      // 3. Chamada para Dados de Análise IA
      const analysisResponse = await fetch(
        "http://127.0.0.1:8080/api/v1/dashboard/analysis",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ period: period }),
        }
      );
      if (!analysisResponse.ok) {
        throw new Error(
          `Erro API Análise: ${analysisResponse.status} ${analysisResponse.statusText}`
        );
      }
      const analysisData = await analysisResponse.json();
      setAnaliseIaData(analysisData);
    } catch (err) {
      console.error("Erro ao buscar dados do dashboard:", err);
      setError(err.message); // Define a mensagem de erro para exibir na tela
    } finally {
      setLoading(false);
    }
  }, []);

  // Efeito para carregar dados na montagem inicial
  useEffect(() => {
    fetchDashboardData(selectedPeriod);
  }, [fetchDashboardData, selectedPeriod]);

  // Função para lidar com o clique no Refresh
  const handleRefresh = () => {
    fetchDashboardData(selectedPeriod);
  };

  // Função para lidar com a seleção do Filtro
  const handleFilterSelect = (period) => {
    setSelectedPeriod(period);
    setIsFilterOpen(false);
    // O useEffect acima já vai disparar o fetchDashboardData quando selectedPeriod mudar
  };

  if (error) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="text-red-500 text-xl p-8 border border-red-800 rounded-lg bg-red-900/20 flex flex-col items-center gap-4">
          <AlertCircle className="w-12 h-12" />
          <span>Erro ao carregar dashboard: {error}</span>
          <button
            onClick={handleRefresh}
            className="px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded text-white text-sm"
          >
            Tentar Novamente
          </button>
        </div>
      </div>
    );
  }

  if (loading && !producaoData && !faturamentoData && !analiseIaData) {
    // Mostra loading inicial apenas se não houver nenhum dado carregado ainda
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="text-cyan-400 text-xl flex items-center gap-2">
          <RefreshCw className="w-6 h-6 animate-spin" />
          Carregando dados em tempo real...
        </div>
      </div>
    );
  }

  return (
    <div
      className="min-h-screen bg-slate-950 text-white p-6 w-full max-w-full"
      onClick={() => isFilterOpen && setIsFilterOpen(false)}
    >
      {/* Header Geral */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold text-white mb-1">
            TORRE DE CONTROLE INTEGRADA
          </h1>
          <p className="text-slate-400">
            Visão Unificada: Produção, Financeiro e IA |{" "}
            <span className="text-cyan-400 font-medium">{selectedPeriod}</span>
          </p>
        </div>
        <div className="flex gap-3 relative">
          {/* Botão de Filtro */}
          <button
            className={`p-2 rounded-lg transition-all ${
              isFilterOpen
                ? "bg-cyan-600 text-white"
                : "bg-slate-800 hover:bg-slate-700 text-slate-400"
            }`}
            onClick={(e) => {
              e.stopPropagation();
              setIsFilterOpen(!isFilterOpen);
            }}
          >
            <Filter className="w-5 h-5" />
          </button>

          {/* Menu Dropdown do Filtro */}
          {isFilterOpen && (
            <div className="absolute top-12 right-12 w-48 bg-slate-900 border border-slate-800 rounded-lg shadow-xl z-50 overflow-hidden">
              <div className="p-2 border-b border-slate-800 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Período
              </div>
              {periodOptions.map((period) => (
                <button
                  key={period}
                  className="w-full text-left px-4 py-3 text-sm text-slate-300 hover:bg-slate-800 hover:text-white flex items-center justify-between transition-colors"
                  onClick={() => handleFilterSelect(period)}
                >
                  {period}
                  {selectedPeriod === period && (
                    <Check className="w-4 h-4 text-cyan-400" />
                  )}
                </button>
              ))}
            </div>
          )}

          {/* Botão de Refresh */}
          <button
            className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg transition-colors text-slate-400 hover:text-white"
            onClick={handleRefresh}
            disabled={loading}
          >
            <RefreshCw className={`w-5 h-5 ${loading ? "animate-spin" : ""}`} />
          </button>
        </div>
      </div>

      {/* --- NOVA SEÇÃO: VISÃO OPERACIONAL (INJEÇÃO SEGURA) --- */}
      <OperationalOverview />

      {/* Menu de Navegação (Abas) */}
      <div className="flex gap-2 mb-6 bg-slate-900 rounded-lg p-2 border border-slate-800 w-fit">
        <button
          onClick={() => setActiveTab("producao")}
          className={`flex items-center gap-2 px-6 py-3 rounded-lg transition-all ${
            activeTab === "producao"
              ? "bg-cyan-600 text-white shadow-lg"
              : "text-slate-400 hover:text-white hover:bg-slate-800"
          }`}
        >
          <BarChart3 className="w-5 h-5" />
          <span className="font-semibold">Produção</span>
        </button>
        <button
          onClick={() => setActiveTab("faturamento")}
          className={`flex items-center gap-2 px-6 py-3 rounded-lg transition-all ${
            activeTab === "faturamento"
              ? "bg-emerald-600 text-white shadow-lg"
              : "text-slate-400 hover:text-white hover:bg-slate-800"
          }`}
        >
          <DollarSign className="w-5 h-5" />
          <span className="font-semibold">Faturamento</span>
        </button>
        <button
          onClick={() => setActiveTab("analise-ia")}
          className={`flex items-center gap-2 px-6 py-3 rounded-lg transition-all ${
            activeTab === "analise-ia"
              ? "bg-purple-600 text-white shadow-lg"
              : "text-slate-400 hover:text-white hover:bg-slate-800"
          }`}
        >
          <Brain className="w-5 h-5" />
          <span className="font-semibold">Análise IA</span>
        </button>
      </div>

      {/* Conteúdo das Abas (com loading state sutil se já houver dados) */}
      <div
        className={`transition-all duration-300 ${
          loading && (producaoData || faturamentoData || analiseIaData)
            ? "opacity-70 pointer-events-none"
            : ""
        }`}
      >
        {activeTab === "producao" && producaoData && (
          <ProductionContent data={producaoData} />
        )}
        {activeTab === "faturamento" && faturamentoData && (
          <FaturamentoContent data={faturamentoData} />
        )}
        {activeTab === "analise-ia" && analiseIaData && (
          <AnaliseIAContent data={analiseIaData} />
        )}
      </div>
    </div>
  );
};

export default Dashboard;
