import React from "react";
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
import {
  DollarSign,
  TrendingUp,
  Users,
  Activity,
  Briefcase,
  Clock,
  Target,
} from "lucide-react";

// Mock Data (Initial State)
const mockData = {
  mrr: "€ 45.000",
  tcv: "€ 120.000",
  ticket_medio: "€ 15.000",
  revenue_backlog: "€ 200.000",
  conversion_rate: "12%",
  win_rate: "18%",
  sales_cycle: "4.5 meses",
  lead_qualification_rate: "35%",
  cac: "€ 2.500",
  ltv: "€ 35.000",
  margin: "28%",
  churn_rate: "2.5%",
  nps: "72",
};

const monthlyRevenueData = [
  { name: "Jan", revenue: 40000 },
  { name: "Fev", revenue: 42000 },
  { name: "Mar", revenue: 45000 },
  { name: "Abr", revenue: 44000 },
  { name: "Mai", revenue: 48000 },
  { name: "Jun", revenue: 52000 },
];

const pipelineData = [
  { name: "Leads", value: 100 },
  { name: "Qualificados", value: 35 },
  { name: "Proposta", value: 20 },
  { name: "Negociação", value: 10 },
  { name: "Fechado", value: 4 },
];

const KPICard = ({ title, value, icon: Icon, trend }) => (
  <div className="bg-gray-800 p-4 rounded-lg border border-gray-700 flex items-center justify-between">
    <div>
      <p className="text-gray-400 text-sm">{title}</p>
      <h3 className="text-2xl font-bold text-white mt-1">{value}</h3>
      {trend && <p className="text-xs text-green-400 mt-1">{trend}</p>}
    </div>
    <div className="p-3 bg-gray-700 rounded-full">
      <Icon size={24} className="text-blue-400" />
    </div>
  </div>
);

const CommercialDashboard = () => {
  return (
    <div className="space-y-6">
      {/* Section 1: Revenue & Sales */}
      <div>
        <h2 className="text-xl font-semibold text-white mb-4 flex items-center gap-2">
          <DollarSign className="text-green-400" /> Receita e Vendas
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <KPICard
            title="MRR (Recorrente)"
            value={mockData.mrr}
            icon={Activity}
            trend="+5% vs mês anterior"
          />
          <KPICard
            title="TCV (Contratos)"
            value={mockData.tcv}
            icon={Briefcase}
          />
          <KPICard
            title="Ticket Médio"
            value={mockData.ticket_medio}
            icon={DollarSign}
          />
          <KPICard
            title="Backlog Receita"
            value={mockData.revenue_backlog}
            icon={Clock}
          />
        </div>
      </div>

      {/* Section 2: Pipeline Efficiency */}
      <div>
        <h2 className="text-xl font-semibold text-white mb-4 flex items-center gap-2">
          <TrendingUp className="text-blue-400" /> Eficiência do Funil
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <KPICard
            title="Taxa Conversão"
            value={mockData.conversion_rate}
            icon={Target}
          />
          <KPICard
            title="Win Rate"
            value={mockData.win_rate}
            icon={TrendingUp}
            trend="Abaixo da meta (20%)"
          />
          <KPICard
            title="Ciclo de Vendas"
            value={mockData.sales_cycle}
            icon={Clock}
          />
          <KPICard
            title="Qualificação Leads"
            value={mockData.lead_qualification_rate}
            icon={Users}
          />
        </div>
      </div>

      {/* Section 3: Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
          <h3 className="text-lg font-medium text-white mb-4">
            Evolução de Receita (Semestral)
          </h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={monthlyRevenueData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                <XAxis dataKey="name" stroke="#9CA3AF" />
                <YAxis stroke="#9CA3AF" />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1F2937",
                    borderColor: "#374151",
                    color: "#F3F4F6",
                  }}
                />
                <Line
                  type="monotone"
                  dataKey="revenue"
                  stroke="#3B82F6"
                  strokeWidth={2}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
          <h3 className="text-lg font-medium text-white mb-4">
            Funil de Vendas Atual
          </h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={pipelineData} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                <XAxis type="number" stroke="#9CA3AF" />
                <YAxis
                  dataKey="name"
                  type="category"
                  stroke="#9CA3AF"
                  width={100}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#1F2937",
                    borderColor: "#374151",
                    color: "#F3F4F6",
                  }}
                />
                <Bar dataKey="value" fill="#10B981" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Section 4: Costs & Retention */}
      <div>
        <h2 className="text-xl font-semibold text-white mb-4 flex items-center gap-2">
          <Users className="text-purple-400" /> Custos e Retenção
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <KPICard title="CAC" value={mockData.cac} icon={DollarSign} />
          <KPICard title="LTV" value={mockData.ltv} icon={TrendingUp} />
          <KPICard
            title="Churn Rate"
            value={mockData.churn_rate}
            icon={Activity}
            trend="Estável"
          />
          <KPICard title="NPS" value={mockData.nps} icon={Users} />
        </div>
      </div>
    </div>
  );
};

export default CommercialDashboard;
