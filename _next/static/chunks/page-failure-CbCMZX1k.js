import{r as e}from"./framework-CRVBm-_k.js";import{d as t,s as n,t as r}from"./typography-Dh_zxwFR.js";var i=e();function a({error:e,reset:a}){let{t:o}=t(),s=()=>window.location.reload();return(0,i.jsxs)(`main`,{className:`ems-recovery`,children:[(0,i.jsx)(`style`,{children:`
        .ems-recovery {
          box-sizing: border-box; min-height: 100svh; padding: 24px;
          display: grid; place-content: center;
          font: ${n.fontSize.body}/${n.lineHeight.body} Arial, Helvetica, sans-serif;
          color: ${n.color.text}; background: ${n.color.canvas};
        }
        .ems-recovery section { width: min(100%, 440px); margin: auto; }
        .ems-recovery h1 { font-size: ${n.fontSize.title}; line-height: 1.35; }
        .ems-recovery p { color: ${n.color.textSecondary}; }
        .ems-recovery nav { display: flex; flex-wrap: wrap; gap: 8px; margin: 24px 0; }
        .ems-recovery button {
          font: inherit; min-height: 44px; padding: 10px 16px; border-radius: ${n.radius.control};
          border: 1px solid ${n.color.borderStrong}; cursor: pointer;
          color: ${n.color.text}; background: ${n.color.surface};
        }
        .ems-recovery button:first-child {
          color: ${n.color.surface}; background: ${n.color.brand};
        }
        @media (hover: hover) and (pointer: fine) {
          .ems-recovery button:hover { filter: brightness(.95); }
        }
        .ems-recovery :focus-visible { outline: 2px solid ${n.color.focus}; outline-offset: 3px; }
        .ems-recovery summary { cursor: pointer; padding: 8px 0; }
        .ems-recovery pre { white-space: pre-wrap; overflow-wrap: anywhere; font-size: ${n.fontSize.caption}; }
      `}),(0,i.jsxs)(`section`,{"aria-labelledby":`recovery-title`,children:[(0,i.jsx)(`p`,{children:o(`GREENBUDDIES · ENERGY MANAGEMENT`)}),(0,i.jsx)(r,{level:1,size:`title`,id:`recovery-title`,children:o(`This view stopped working`)}),(0,i.jsx)(`p`,{children:o(`Try opening it again, or return to the portfolio. If it happens again, share the error details below with support.`)}),(0,i.jsxs)(`nav`,{"aria-label":o(`Page recovery`),children:[(0,i.jsx)(`button`,{type:`button`,onClick:a??s,children:o(`Try again`)}),(0,i.jsx)(`button`,{type:`button`,onClick:()=>{window.location.hash=`portfolio`,s()},children:o(`Open portfolio`)}),a&&(0,i.jsx)(`button`,{type:`button`,onClick:s,children:o(`Reload page`)})]}),(0,i.jsxs)(`details`,{children:[(0,i.jsx)(`summary`,{children:o(`Error details`)}),(0,i.jsx)(`pre`,{children:o(e?.digest?o(`Error reference: {0}`,{0:e.digest}):e?.stack||e?.message||`The browser could not finish loading this view. Please reload the page.`)})]})]})]})}export{a as t};