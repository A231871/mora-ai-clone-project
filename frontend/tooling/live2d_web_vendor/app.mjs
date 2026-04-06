/**
 * Live2D Cubism 4 player for Shizuki (PixiJS + pixi-live2d-display-lipsyncpatch, MIT).
 * Built to IIFE for Android WebView (file:// cannot load ES modules). Cubism Core: separate script.
 */
import * as PIXI from "pixi.js";
import { Live2DModel } from "pixi-live2d-display-lipsyncpatch/cubism4";

const MODEL_JSON = "../Shizuki_Real.model3.json";

function hostPost(msg) {
  try {
    if (typeof ShizukiHost !== "undefined" && ShizukiHost.postMessage) {
      ShizukiHost.postMessage(String(msg));
    }
  } catch (_) {}
}

function setParam(model, id, value, weight = 1) {
  if (!model?.internalModel?.coreModel) return;
  const core = model.internalModel.coreModel;
  try {
    core.setParameterValueById(id, value, weight);
  } catch (e) {
    console.warn("setParam", id, e);
  }
}

function resetExpression(model) {
  if (!model) return;
  const ids = [
    "ParamMouthOpenY",
    "ParamMouthForm",
    "ParamEyeLSmile",
    "ParamEyeRSmile",
    "ParamBrowLY",
    "ParamBrowRY",
    "ParamAngleX",
    "ParamAngleY",
  ];
  for (const id of ids) setParam(model, id, 0);
}

let app = null;
let liveModel = null;
let emotionKey = "idle";
let talkPhase = 0;

function applyEmotionStatic(model, key) {
  if (!model) return;
  resetExpression(model);
  switch (key) {
    case "idle":
      break;
    case "smile":
    case "cheer":
    case "exciting":
      setParam(model, "ParamEyeLSmile", key === "smile" ? 0.85 : 1);
      setParam(model, "ParamEyeRSmile", key === "smile" ? 0.85 : 1);
      setParam(model, "ParamMouthForm", key === "exciting" ? 0.35 : 0.2);
      if (key === "exciting" || key === "cheer") {
        setParam(model, "ParamAngleX", 12);
        setParam(model, "ParamAngleY", -8);
      }
      break;
    case "sad":
      setParam(model, "ParamBrowLY", -0.65);
      setParam(model, "ParamBrowRY", -0.65);
      setParam(model, "ParamMouthForm", -0.35);
      setParam(model, "ParamEyeLOpen", 0.85);
      setParam(model, "ParamEyeROpen", 0.85);
      break;
    case "talk":
      setParam(model, "ParamMouthOpenY", 0.15);
      break;
    default:
      break;
  }
}

window.__shizukiSetEmotion = function (key) {
  emotionKey = key || "idle";
  if (!liveModel) return;
  if (emotionKey !== "talk") talkPhase = 0;
  applyEmotionStatic(liveModel, emotionKey);
};

async function main() {
  const host = document.getElementById("app");
  if (!host) {
    hostPost("error:no_host");
    return;
  }

  try {
    const w = window.innerWidth || 512;
    const h = window.innerHeight || 640;

    app = new PIXI.Application({
      width: w,
      height: h,
      backgroundAlpha: 0,
      antialias: true,
      resolution: window.devicePixelRatio || 1,
      autoDensity: true,
    });
    host.appendChild(app.view);

    const model = await Live2DModel.from(MODEL_JSON, {
      autoInteract: false,
      ticker: app.ticker,
    });

    liveModel = model;
    model.anchor.set(0.5, 0.52);
    model.x = w / 2;
    model.y = h * 0.48;
    const b = model.getLocalBounds?.() || { width: model.width, height: model.height };
    const mw = Math.max(b.width || model.width || 400, 1);
    const mh = Math.max(b.height || model.height || 600, 1);
    const sc = Math.min(w / mw, h / mh) * 0.95;
    model.scale.set(sc);
    app.stage.addChild(model);

    app.ticker.add(() => {
      if (!liveModel || emotionKey !== "talk") return;
      talkPhase += app.ticker.deltaMS * 0.01;
      const v = (Math.sin(talkPhase * 0.35) * 0.5 + 0.5) * 0.92;
      setParam(liveModel, "ParamMouthOpenY", v);
      setParam(liveModel, "ParamMouthForm", 0.25);
    });

    window.addEventListener("resize", () => {
      if (!app || !liveModel) return;
      const nw = window.innerWidth || w;
      const nh = window.innerHeight || h;
      app.renderer.resize(nw, nh);
      liveModel.x = nw / 2;
      liveModel.y = nh * 0.48;
      const bb = liveModel.getLocalBounds?.() || {
        width: liveModel.width,
        height: liveModel.height,
      };
      const nnw = Math.max(bb.width || liveModel.width || 400, 1);
      const nnh = Math.max(bb.height || liveModel.height || 600, 1);
      const nsc = Math.min(nw / nnw, nh / nnh) * 0.95;
      liveModel.scale.set(nsc);
    });

    applyEmotionStatic(liveModel, emotionKey);
    hostPost("ready");
  } catch (e) {
    console.error(e);
    hostPost("error:" + (e && e.message ? e.message : String(e)));
  }
}

main();
