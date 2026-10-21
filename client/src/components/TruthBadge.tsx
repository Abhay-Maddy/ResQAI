import React from 'react';
import { ShieldCheck, Sparkles, CheckCircle2, HelpCircle, AlertTriangle, Clock } from 'lucide-react';
import { useTranslation } from '../i18n/I18nContext';
import './TruthBadge.css';

export type TruthLabelType = 
  | 'OFFICIAL_WARNING' 
  | 'ML_ASSESSMENT' 
  | 'VERIFIED_INCIDENT' 
  | 'UNVERIFIED_REPORT' 
  | 'DEMO_DATA' 
  | 'STALE';

interface TruthBadgeProps {
  type: TruthLabelType;
  severity?: 'critical' | 'warn' | 'info' | 'safe';
  timestamp?: string;
  source?: string;
  confidence?: number;
  customLabel?: string;
  size?: 'sm' | 'md' | 'lg';
}

export const TruthBadge: React.FC<TruthBadgeProps> = ({
  type,
  severity,
  timestamp,
  source,
  confidence,
  customLabel,
  size = 'md'
}) => {
  const { t } = useTranslation();

  const getBadgeConfig = () => {
    switch (type) {
      case 'OFFICIAL_WARNING':
        return {
          icon: <ShieldCheck className="truth-badge-icon" aria-hidden="true" />,
          defaultLabel: t('truthLabels.OFFICIAL_WARNING'),
          cssClass: `badge-official ${severity ? `severity-${severity}` : 'severity-critical'}`
        };
      case 'ML_ASSESSMENT':
        return {
          icon: <Sparkles className="truth-badge-icon" aria-hidden="true" />,
          defaultLabel: t('truthLabels.ML_ASSESSMENT'),
          cssClass: 'badge-ml'
        };
      case 'VERIFIED_INCIDENT':
        return {
          icon: <CheckCircle2 className="truth-badge-icon" aria-hidden="true" />,
          defaultLabel: t('truthLabels.VERIFIED_INCIDENT'),
          cssClass: 'badge-verified'
        };
      case 'UNVERIFIED_REPORT':
        return {
          icon: <HelpCircle className="truth-badge-icon" aria-hidden="true" />,
          defaultLabel: t('truthLabels.UNVERIFIED_REPORT'),
          cssClass: 'badge-unverified'
        };
      case 'DEMO_DATA':
        return {
          icon: <AlertTriangle className="truth-badge-icon" aria-hidden="true" />,
          defaultLabel: t('truthLabels.DEMO_DATA'),
          cssClass: 'badge-demo'
        };
      case 'STALE':
        return {
          icon: <Clock className="truth-badge-icon" aria-hidden="true" />,
          defaultLabel: t('truthLabels.STALE'),
          cssClass: 'badge-stale'
        };
    }
  };

  const config = getBadgeConfig();
  const label = customLabel || config.defaultLabel;

  return (
    <span 
      className={`truth-badge truth-badge-${size} ${config.cssClass}`}
      role="status"
      title={source ? `${label} • Source: ${source}${timestamp ? ` • ${timestamp}` : ''}` : label}
    >
      {config.icon}
      <span className="truth-badge-text">{label}</span>
      {confidence !== undefined && (
        <span className="truth-badge-meta">({Math.round(confidence * 100)}%)</span>
      )}
      {source && (
        <span className="truth-badge-source">[{source}]</span>
      )}
    </span>
  );
};
