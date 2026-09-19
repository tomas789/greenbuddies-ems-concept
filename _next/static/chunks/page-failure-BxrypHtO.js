import{r as e}from"./framework-CRVBm-_k.js";import{s as t,t as n}from"./typography-Dtz7R_Dv.js";var r=e();function i({error:e,reset:i}){let a=()=>window.location.reload();return(0,r.jsxs)(`main`,{className:`ems-recovery`,children:[(0,r.jsx)(`style`,{children:`
        .ems-recovery {
          box-sizing: border-box; min-height: 100svh; padding: 24px;
          display: grid; place-content: center;
          font: ${t.fontSize.body}/${t.lineHeight.body} Arial, Helvetica, sans-serif;
          color: ${t.color.text}; background: ${t.color.canvas};
        }
        .ems-recovery section { width: min(100%, 440px); margin: auto; }
        .ems-recovery h1 { font-size: ${t.fontSize.title}; line-height: 1.35; }
        .ems-recovery p { color: ${t.color.textSecondary}; }
        .ems-recovery nav { display: flex; flex-wrap: wrap; gap: 8px; margin: 24px 0; }
        .ems-recovery button {
          font: inherit; min-height: 44px; padding: 10px 16px; border-radius: 6px;
          border: 1px solid ${t.color.borderStrong}; cursor: pointer;
          color: ${t.color.text}; background: ${t.color.surface};
        }
        .ems-recovery button:first-child {
          color: ${t.color.surface}; background: ${t.color.brand};
        }
        @media (hover: hover) and (pointer: fine) {
          .ems-recovery button:hover { filter: brightness(.95); }
        }
        .ems-recovery :focus-visible { outline: 2px solid ${t.color.focus}; outline-offset: 3px; }
        .ems-recovery summary { cursor: pointer; padding: 8px 0; }
        .ems-recovery pre { white-space: pre-wrap; overflow-wrap: anywhere; font-size: ${t.fontSize.caption}; }
      `}),(0,r.jsxs)(`section`,{"aria-labelledby":`recovery-title`,children:[(0,r.jsx)(`p`,{children:`GREENBUDDIES · ENERGY MANAGEMENT`}),(0,r.jsx)(n,{level:1,size:`title`,id:`recovery-title`,children:`This view stopped working`}),(0,r.jsx)(`p`,{children:`Try opening it again, or return to the portfolio. If it happens again, share the error details below with support.`}),(0,r.jsxs)(`nav`,{"aria-label":`Page recovery`,children:[(0,r.jsx)(`button`,{type:`button`,onClick:i??a,children:`Try again`}),(0,r.jsx)(`button`,{type:`button`,onClick:()=>{window.location.hash=`portfolio`,a()},children:`Open portfolio`}),i&&(0,r.jsx)(`button`,{type:`button`,onClick:a,children:`Reload page`})]}),(0,r.jsxs)(`details`,{children:[(0,r.jsx)(`summary`,{children:`Error details`}),(0,r.jsx)(`pre`,{children:e?.digest?`Error reference: ${e.digest}`:e?.stack||e?.message||`The browser could not finish loading this view. Please reload the page.`})]})]})]})}export{i as t};