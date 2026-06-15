// React 19.2 <Activity> demo (issue #3883, Phase 1).
//
// A tab switcher that keeps the inactive tab MOUNTED inside
// <Activity mode="hidden"> instead of unmounting it. Switching tabs therefore
// preserves the hidden tab's local state (the draft <input> value), while React
// deactivates its effects and defers its updates until it becomes visible again.
//
// This component is rendered two ways in the dummy app to prove both paths:
//   - /client_side_activity (prerender: false -- CSR only)
//   - /server_side_activity (prerender: true -- SSR + hydration)
//
// SSR note (verified against react-dom 19.2 renderToString): hidden Activity
// subtrees are NOT included in the server HTML. Only the visible tab is
// prerendered; the hidden tab renders on the client after hydration, without
// any hydration mismatch. See docs/oss/building-features/react-19-activity.md.
import React, { Activity, useEffect, useState } from 'react';

const TAB_NAMES = ['profile', 'drafts'] as const;
type TabName = (typeof TAB_NAMES)[number];

export type ActivityTabSwitcherProps = {
  initialTab?: TabName;
};

function TabPanel({ tab }: { tab: TabName }) {
  // Local state proves preservation: hiding the panel via Activity keeps this
  // value; a conditional `{active && <TabPanel/>}` render would lose it.
  const [draft, setDraft] = useState('');

  // Effects deactivate while hidden and re-run when visible again. The status
  // text demonstrates the lifecycle; the draft state survives the whole time.
  const [effectStatus, setEffectStatus] = useState('effects never activated');
  useEffect(() => {
    setEffectStatus('effects active');
    return () => {
      setEffectStatus('effects deactivated (state preserved)');
    };
  }, []);

  return (
    <div
      className="activity-tab-panel"
      data-tab-panel={tab}
      id={`activity-panel-${tab}`}
      role="tabpanel"
      aria-labelledby={`activity-tab-${tab}`}
    >
      <h4>The {tab} tab</h4>
      <p data-effect-status={tab}>{effectStatus}</p>
      <label htmlFor={`activity-draft-${tab}`}>Draft for {tab}:</label>{' '}
      <input
        id={`activity-draft-${tab}`}
        data-draft-input={tab}
        value={draft}
        onChange={(event) => setDraft(event.target.value)}
        placeholder={`Type a ${tab} draft...`}
      />
    </div>
  );
}

const ActivityTabSwitcher = ({ initialTab = 'profile' }: ActivityTabSwitcherProps) => {
  const [activeTab, setActiveTab] = useState<TabName>(initialTab);

  return (
    <div className="activity-tab-switcher">
      <h3>React 19.2 &lt;Activity&gt; tab switcher</h3>
      <div role="tablist" aria-label="Activity demo tabs">
        {TAB_NAMES.map((tab) => (
          <button
            key={tab}
            type="button"
            role="tab"
            id={`activity-tab-${tab}`}
            aria-selected={tab === activeTab}
            aria-controls={`activity-panel-${tab}`}
            data-tab-button={tab}
            onClick={() => setActiveTab(tab)}
          >
            {tab}
          </button>
        ))}
      </div>
      {TAB_NAMES.map((tab) => (
        <Activity key={tab} mode={tab === activeTab ? 'visible' : 'hidden'}>
          <TabPanel tab={tab} />
        </Activity>
      ))}
    </div>
  );
};

export default ActivityTabSwitcher;
