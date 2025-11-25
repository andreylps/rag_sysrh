import React from "react";
import { CheckCircle2, XCircle, AlertCircle } from "lucide-react";

const HealthStatusCard = ({ service, status, details }) => {
  const getStatusConfig = (status) => {
    switch (status) {
      case "ok":
        return {
          icon: <CheckCircle2 className="w-6 h-6 text-green-500" />,
          bgColor: "bg-green-500/10",
          borderColor: "border-green-500/20",
          textColor: "text-green-400",
        };
      case "error":
        return {
          icon: <XCircle className="w-6 h-6 text-red-500" />,
          bgColor: "bg-red-500/10",
          borderColor: "border-red-500/20",
          textColor: "text-red-400",
        };
      default:
        return {
          icon: <AlertCircle className="w-6 h-6 text-yellow-500" />,
          bgColor: "bg-yellow-500/10",
          borderColor: "border-yellow-500/20",
          textColor: "text-yellow-400",
        };
    }
  };

  const config = getStatusConfig(status);

  return (
    <div
      className={`p-4 rounded-lg border ${config.borderColor} ${config.bgColor} backdrop-blur-sm transition-all duration-200 hover:scale-[1.02]`}
    >
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          {config.icon}
          <div>
            <h3 className="font-semibold text-gray-100">{service}</h3>
            <p
              className={`text-sm ${config.textColor} font-medium uppercase tracking-wider`}
            >
              {status}
            </p>
          </div>
        </div>
      </div>

      {details && (
        <div className="mt-3 pt-3 border-t border-gray-700/50">
          <p className="text-xs text-gray-400 font-mono break-all">
            {typeof details === "object"
              ? JSON.stringify(details, null, 2)
              : details}
          </p>
        </div>
      )}
    </div>
  );
};

export default HealthStatusCard;
