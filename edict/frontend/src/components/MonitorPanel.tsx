import { useEffect, useRef, useState } from 'react';
import { useStore, DEPTS, isEdict, stateLabel } from '../store';
import { api, type OfficialInfo } from '../api';

export default function MonitorPanel() {
  const liveStatus = useStore((s) => s.liveStatus);
  const agentsStatusData = useStore((s) => s.agentsStatusData);
  const officialsData = useStore((s) => s.officialsData);
  const loadAgentsStatus = useStore((s) => s.loadAgentsStatus);
  const setModalTaskId = useStore((s) => s.setModalTaskId);
  const toast = useStore((s) => s.toast);

  useEffect(() => {
    loadAgentsStatus();
  }, [loadAgentsStatus]);

  const tasks = liveStatus?.tasks || [];
  const activeTasks = tasks.filter((t) => isEdict(t) && t.state !== 'Done' && t.state !== 'Next');

  // Build official map
  const offMap: Record<string, OfficialInfo> = {};
  if (officialsData?.officials) {
    officialsData.officials.forEach((o) => { offMap[o.id] = o; });
  }

  // Agent wake
  const handleWake = async (agentId: string) => {
    try {
      const r = await api.agentWake(agentId);
      toast(r.message || '唤醒指令已发出');
      setTimeout(() => loadAgentsStatus(), 30000);
    } catch { toast('唤醒失败', 'err'); }
  };

  const handleWakeAll = async () => {
    if (!agentsStatusData) return;
    const toWake = agentsStatusData.agents.filter(
      (a) => a.id !== 'main' && a.status !== 'running' && a.status !== 'unconfigured'
    );
    if (!toWake.length) { toast('所有 Agent 均已在线'); return; }
    toast(`正在唤醒 ${toWake.length} 个 Agent...`);
    for (const a of toWake) {
      try { await api.agentWake(a.id); } catch { /* ignore */ }
    }
    toast(`${toWake.length} 个唤醒指令已发出，30秒后刷新状态`);
    setTimeout(() => loadAgentsStatus(), 30000);
  };

  // Agent Status Panel
  const asData = agentsStatusData;
  const filtered = asData?.agents?.filter((a) => a.id !== 'main') || [];
  const running = filtered.filter((a) => a.status === 'running').length;
  const idle = filtered.filter((a) => a.status === 'idle').length;
  const offline = filtered.filter((a) => a.status === 'offline').length;
  const unconf = filtered.filter((a) => a.status === 'unconfigured').length;
  const gw = asData?.gateway;
  const gwCls = gw?.probe ? 'ok' : gw?.alive ? 'warn' : 'err';

  return (
    <div>
      {/* Agent Status Panel */}
      {asData && asData.ok && (
        <div className="as-panel">
          <div className="as-header">
            <span className="as-title">🔌 Agent 在线状态</span>
            <span className={`as-gw ${gwCls}`}>Gateway: {gw?.status || '未知'}</span>
            <button className="btn-refresh" onClick={() => loadAgentsStatus()} style={{ marginLeft: 8 }}>
              🔄 刷新
            </button>
            {(offline + unconf > 0) && (
              <button className="btn-refresh" onClick={handleWakeAll} style={{ marginLeft: 4, borderColor: 'var(--warn)', color: 'var(--warn)' }}>
                ⚡ 全部唤醒
              </button>
            )}
          </div>
          <div className="as-grid">
            {filtered.map((a) => {
              const canWake = a.status !== 'running' && a.status !== 'unconfigured' && gw?.alive;
              return (
                <div key={a.id} className="as-card" title={`${a.role} · ${a.statusLabel}`}>
                  <div className={`as-dot ${a.status}`} />
                  <div style={{ fontSize: 22 }}>{a.emoji}</div>
                  <div style={{ fontSize: 12, fontWeight: 700 }}>{a.label}</div>
                  <div style={{ fontSize: 10, color: 'var(--muted)' }}>{a.role}</div>
                  <div style={{ fontSize: 10, color: 'var(--muted)' }}>{a.statusLabel}</div>
                  {a.lastActive ? (
                    <div style={{ fontSize: 10, color: 'var(--muted)' }}>⏰ {a.lastActive}</div>
                  ) : (
                    <div style={{ fontSize: 10, color: 'var(--muted)' }}>无活动记录</div>
                  )}
                  {canWake && (
                    <button className="as-wake-btn" onClick={(e) => { e.stopPropagation(); handleWake(a.id); }}>
                      ⚡ 唤醒
                    </button>
                  )}
                </div>
              );
            })}
          </div>
          <div className="as-summary">
            <span><span className="as-dot running" style={{ position: 'static', width: 8, height: 8 }} /> {running} 运行中</span>
            <span><span className="as-dot idle" style={{ position: 'static', width: 8, height: 8 }} /> {idle} 待命</span>
            {offline > 0 && <span><span className="as-dot offline" style={{ position: 'static', width: 8, height: 8 }} /> {offline} 离线</span>}
            {unconf > 0 && <span><span className="as-dot unconfigured" style={{ position: 'static', width: 8, height: 8 }} /> {unconf} 未配置</span>}
            <span style={{ marginLeft: 'auto', fontSize: 10, color: 'var(--muted)' }}>
              检测于 {(asData.checkedAt || '').substring(11, 19)}
            </span>
          </div>
        </div>
      )}

      {/* Duty Grid */}
      <div className="duty-grid">
        {DEPTS.map((d) => {
          const myTasks = activeTasks.filter((t) => t.org === d.label);
          const isActive = myTasks.some((t) => t.state === 'Doing');
          const isBlocked = myTasks.some((t) => t.state === 'Blocked');
          const off = offMap[d.id];
          const hb = off?.heartbeat || { status: 'idle', label: '⚪' };
          const dotCls = isBlocked ? 'blocked' : isActive ? 'busy' : hb.status === 'active' ? 'active' : 'idle';
          const statusText = isBlocked ? '⚠️ 阻塞' : isActive ? '⚙️ 执行中' : hb.status === 'active' ? '🟢 活跃' : '⚪ 候命';
          const cardCls = isBlocked ? 'blocked-card' : isActive ? 'active-card' : '';

          return (
            <div key={d.id} className={`duty-card ${cardCls}`}>
              <div className="dc-hdr">
                <span className="dc-emoji">{d.emoji}</span>
                <div className="dc-info">
                  <div className="dc-name">{d.label}</div>
                  <div className="dc-role">{d.role} · {d.rank}</div>
                </div>
                <div className="dc-status">
                  <span className={`dc-dot ${dotCls}`} />
                  <span>{statusText}</span>
                </div>
              </div>
              <div className="dc-body">
                {myTasks.length > 0 ? (
                  myTasks.map((t) => (
                    <div key={t.id} className="dc-task" onClick={() => setModalTaskId(t.id)}>
                      <div className="dc-task-id">{t.id}</div>
                      <div className="dc-task-title">{t.title || '(无标题)'}</div>
                      {t.now && t.now !== '-' && (
                        <div className="dc-task-now">{t.now.substring(0, 70)}</div>
                      )}
                      <div className="dc-task-meta">
                        <span className={`tag st-${t.state}`}>{stateLabel(t)}</span>
                        {t.block && t.block !== '无' && (
                          <span className="tag" style={{ borderColor: '#ff527044', color: 'var(--danger)' }}>🚫{t.block}</span>
                        )}
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="dc-idle">
                    <span style={{ fontSize: 20 }}>🪭</span>
                    <span>候命中</span>
                  </div>
                )}
              </div>
              <div className="dc-footer">
                <span className="dc-model">🤖 {off?.model_short || '待配置'}</span>
                {off?.last_active && <span className="dc-la">⏰ {off.last_active}</span>}
              </div>
            </div>
          );
        })}
      </div>

      {/* Org Chart */}
      <OrgChart 
        agentsStatusData={agentsStatusData} 
        officialsData={officialsData} 
        tasks={activeTasks} 
      />
    </div>
  );
}

interface OrgChartProps {
  agentsStatusData: any;
  officialsData: any;
  tasks: any[];
}

interface LineData {
  id: string;
  from: string;
  to: string;
  color: string;
  active: boolean;
  dashed?: boolean;
  x1: number;
  y1: number;
  x2: number;
  y2: number;
}

function OrgChart({ agentsStatusData, officialsData, tasks }: OrgChartProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [lines, setLines] = useState<LineData[]>([]);

  const getAgent = (id: string) => agentsStatusData?.agents?.find((a: { id: string; [key: string]: any }) => a.id === id);
  const getOfficial = (id: string) => officialsData?.officials?.find((o: { id: string; [key: string]: any }) => o.id === id);

  const renderNode = (id: string, defaultLabel: string, defaultEmoji: string, defaultRole: string, type: 'taizi' | 'secondary' | 'exec' | 'independent') => {
    const agent = getAgent(id);
    const official = getOfficial(id);
    
    const label = agent?.label || official?.label || defaultLabel;
    const emoji = agent?.emoji || official?.emoji || defaultEmoji;
    const role = agent?.role || official?.role || defaultRole;
    const status = agent?.status || 'unconfigured';
    const lastActive = agent?.lastActive || official?.last_active;

    return (
      <div 
        id={`org-node-${id}`} 
        className={`org-node org-node--${type}`}
      >
        <div className={`org-status-dot ${status}`} />
        <span className="org-emoji">{emoji}</span>
        <span className="org-label">{label}</span>
        <span className="org-rank">{role}</span>
        {lastActive && <span className="org-last-active">{lastActive}</span>}
      </div>
    );
  };

  useEffect(() => {
    let rafId: number;
    const updateLines = () => {
      rafId = requestAnimationFrame(() => {
        if (!containerRef.current) return;
        const containerRect = containerRef.current.getBoundingClientRect();
        
        const connections = [
          { id: 'taizi-zhongshu', from: 'taizi', to: 'zhongshu', color: '#a07aff', active: tasks.some(t => t.state === 'Zhongshu') },
          { id: 'taizi-menxia', from: 'taizi', to: 'menxia', color: '#a07aff', active: tasks.some(t => t.state === 'Menxia') },
          { id: 'taizi-shangshu', from: 'taizi', to: 'shangshu', color: '#a07aff', active: tasks.some(t => t.state === 'Review' || t.state === 'Assigned') },
          { id: 'taizi-gongbu', from: 'taizi', to: 'gongbu', color: '#6a9eff', active: tasks.some(t => t.state === 'Doing' && t.org === '工部') },
          { id: 'taizi-bingbu', from: 'taizi', to: 'bingbu', color: '#6a9eff', active: tasks.some(t => t.state === 'Doing' && t.org === '兵部') },
          { id: 'taizi-hubu', from: 'taizi', to: 'hubu', color: '#6a9eff', active: tasks.some(t => t.state === 'Doing' && t.org === '户部') },
          { id: 'taizi-libu', from: 'taizi', to: 'libu', color: '#6a9eff', active: tasks.some(t => t.state === 'Doing' && t.org === '礼部') },
          { id: 'taizi-xingbu', from: 'taizi', to: 'xingbu', color: '#6a9eff', active: tasks.some(t => t.state === 'Doing' && t.org === '刑部') },
          { id: 'taizi-hanlin', from: 'taizi', to: 'hanlin', color: '#6a9eff', active: tasks.some(t => t.state === 'Doing' && t.org === '翰林院') },
          { id: 'taizi-libu_hr', from: 'taizi', to: 'libu_hr', color: '#9b59b6', dashed: true, active: false },
        ];

        const newLines = connections.map(conn => {
          const fromNode = document.getElementById(`org-node-${conn.from}`);
          const toNode = document.getElementById(`org-node-${conn.to}`);
          
          if (!fromNode || !toNode) return null;
          
          const fromRect = fromNode.getBoundingClientRect();
          const toRect = toNode.getBoundingClientRect();
          
          const x1 = fromRect.left + fromRect.width / 2 - containerRect.left;
          const y1 = fromRect.top + fromRect.height / 2 - containerRect.top;
          const x2 = toRect.left + toRect.width / 2 - containerRect.left;
          const y2 = toRect.top + toRect.height / 2 - containerRect.top;
          
          return { ...conn, x1, y1, x2, y2 } as LineData;
        }).filter((l): l is LineData => Boolean(l));
        
        setLines(newLines);
      });
    };

    updateLines();
    setTimeout(updateLines, 100);
    setTimeout(updateLines, 500);
    
    const observer = new ResizeObserver(updateLines);
    if (containerRef.current) {
      observer.observe(containerRef.current);
    }
    window.addEventListener('resize', updateLines);
    
    return () => {
      cancelAnimationFrame(rafId);
      observer.disconnect();
      window.removeEventListener('resize', updateLines);
    };
  }, [tasks, agentsStatusData, officialsData]);

  return (
    <div className="org-chart" ref={containerRef}>
      <div className="org-title">🏯 Agent 组织架构</div>

      <svg className="org-svg-layer">
        {lines.map((line) => (
          <g key={line.id}>
            <line
              x1={line.x1} y1={line.y1}
              x2={line.x2} y2={line.y2}
              stroke={line.color}
              strokeWidth={line.active ? 2.5 : 1}
              strokeOpacity={line.active ? 1 : 0.35}
              strokeDasharray={line.dashed ? '5,5' : undefined}
              className={`org-line ${line.active ? 'org-line--active' : ''}`}
            />
            {line.active && (
              <circle r="3.5" fill={line.color} filter={`drop-shadow(0 0 5px ${line.color})`}>
                <animateMotion
                  dur="1.2s"
                  repeatCount="indefinite"
                  path={`M ${line.x1} ${line.y1} L ${line.x2} ${line.y2}`}
                />
              </circle>
            )}
          </g>
        ))}
      </svg>

      <div className="org-body">
        <div className="org-row org-top">
          {renderNode('taizi', '太子', '🤴', '唯一入口 · 全程协调', 'taizi')}
        </div>

        <div className="org-row org-flat">
          <div className="org-group">
            <div className="org-group-label">按需调用</div>
            <div className="org-group-nodes">
              {renderNode('zhongshu', '中书省', '📜', '方案设计', 'secondary')}
              {renderNode('menxia', '门下省', '🔍', '方案Review', 'secondary')}
              {renderNode('shangshu', '尚书省', '📮', '验收汇总', 'secondary')}
            </div>
          </div>

          <div className="org-group-divider" />

          <div className="org-group">
            <div className="org-group-label">并行执行</div>
            <div className="org-group-nodes">
              {renderNode('gongbu',  '工部',   '🔧', '工程交付', 'exec')}
              {renderNode('bingbu',  '兵部',   '⚔️', '应急巡检', 'exec')}
              {renderNode('hubu',    '户部',   '💰', '资源预算', 'exec')}
              {renderNode('libu',    '礼部',   '📝', '文档汇报', 'exec')}
              {renderNode('xingbu',  '刑部',   '⚖️', '合规审计', 'exec')}
              {renderNode('hanlin',  '翰林院', '📚', '调研搜索', 'exec')}
            </div>
          </div>
        </div>

        <div className="org-row org-independent">
          <div className="org-independent-label">独立运行</div>
          {renderNode('libu_hr', '吏部', '👔', '系统巡检·保活', 'independent')}
        </div>
      </div>
    </div>
  );
}
