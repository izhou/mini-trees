import heronarts.lx.*;
import heronarts.lx.audio.*;
import heronarts.lx.effect.*;
import heronarts.lx.midi.*;
import heronarts.lx.model.*;
import heronarts.lx.output.*;
import heronarts.lx.parameter.*;
import heronarts.lx.pattern.*;
import heronarts.lx.transform.*;
import heronarts.lx.transition.*;
import heronarts.lx.midi.*;
import heronarts.lx.modulator.*;

import heronarts.p2lx.*;
import heronarts.p2lx.ui.*;
import heronarts.p2lx.ui.component.*;
import heronarts.p2lx.ui.control.*;

import ddf.minim.*;
import processing.opengl.*;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

final static int INCHES = 1;
final static int FEET = 12 * INCHES;

final static int SECONDS = 1000;
final static int MINUTES = 60*SECONDS;

final static float CHAIN = -12*INCHES;
final static float BOLT = 22*INCHES;

final static int FRONT = 0;
final static int RIGHT = 1;
final static int REAR = 2;
final static int LEFT = 3;
final static int FRONT_RIGHT = 4;
final static int REAR_RIGHT = 5;
final static int REAR_LEFT = 6;
final static int FRONT_LEFT = 7;

final static int NUM_CHANNELS = 8;
final static int NUM_KNOBS = 8;
final static int NUM_AUTOMATION = 4;

/**
 * This defines the positions of the trees, which are
 * x (left to right), z (front to back), and rotation
 * in degrees.
 */
final static float[][] TREE_POSITIONS = {
  /*  X-pos    Y-pos    Rot  */
  {  15*FEET,  15*FEET,   0  }
};

final static String CLUSTER_CONFIG_FILE = "data/clusters.json";

LXPattern[] getPatternListForChannels() {
  ArrayList<LXPattern> patterns = new ArrayList<LXPattern>();
  // patterns.add(new OrderTest(lx));
  
  // Add patterns here.
  // The order here is the order it shows up in the patterns list
//  patterns.add(new SolidColor(lx));
  // patterns.add(new ClusterLineTest(lx));
  patterns.add(new Twister(lx));
  patterns.add(new CandyCloud(lx));
  patterns.add(new MarkLottor(lx));
  patterns.add(new SolidColor(lx));
  // patterns.add(new DoubleHelix(lx));
  patterns.add(new SparkleHelix(lx));
  patterns.add(new Lightning(lx));
  patterns.add(new SparkleTakeOver(lx));
  patterns.add(new MultiSine(lx));
  patterns.add(new Ripple(lx));
  patterns.add(new SeeSaw(lx));
  patterns.add(new SweepPattern(lx));
  patterns.add(new IceCrystals(lx));
  patterns.add(new ColoredLeaves(lx));
  patterns.add(new Stripes(lx));
  try { patterns.add(new SyphonPattern(lx, this)); } catch (Throwable e) {}
  patterns.add(new AcidTrip(lx));
  patterns.add(new Springs(lx));
  patterns.add(new Lattice(lx));
  patterns.add(new Fire(lx));
  patterns.add(new Fireflies(lx));
  patterns.add(new Fumes(lx));
  patterns.add(new Voronoi(lx));
  patterns.add(new Cells(lx));
  patterns.add(new Bubbles(lx));
  patterns.add(new Pulleys(lx));

  patterns.add(new Wisps(lx));
  patterns.add(new Explosions(lx));
  patterns.add(new BassSlam(lx));
  patterns.add(new Rain(lx));
  patterns.add(new Fade(lx));
  patterns.add(new Strobe(lx));
  patterns.add(new Twinkle(lx));
  patterns.add(new VerticalSweep(lx));
  patterns.add(new RandomColor(lx));
  patterns.add(new ColorStrobe(lx));
  patterns.add(new Pixels(lx));
  patterns.add(new Wedges(lx));
  patterns.add(new Parallax(lx));
  patterns.add(new LowEQ(lx));
  patterns.add(new MidEQ(lx));
  patterns.add(new HighEQ(lx));
  patterns.add(new GalaxyCloud(lx));
  patterns.add(new Verty(lx));
  patterns.add(new Spinny(lx));

  patterns.add(new CameraWrap(lx));

  for (LXPattern pattern : patterns) {
    LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
    pattern.setTransition(t);
  }

  return patterns.toArray(new LXPattern[patterns.size()]);
}

void registerEffects() {
  BlurEffect blurEffect = new BlurEffect(lx);
  ColorEffect colorEffect = new ColorEffect(lx);
  GhostEffect ghostEffect = new GhostEffect(lx);
  ScrambleEffect scrambleEffect = new ScrambleEffect(lx);
  StaticEffect staticEffect = new StaticEffect(lx);
  RotationEffect rotationEffect = new RotationEffect(lx);
  SpinEffect spinEffect = new SpinEffect(lx);
  SpeedEffect speedEffect = new SpeedEffect(lx);
  ColorStrobeTextureEffect colorStrobeTextureEffect = new ColorStrobeTextureEffect(lx);
  FadeTextureEffect fadeTextureEffect = new FadeTextureEffect(lx);
  AcidTripTextureEffect acidTripTextureEffect = new AcidTripTextureEffect(lx);
  CandyTextureEffect candyTextureEffect = new CandyTextureEffect(lx);
  CandyCloudTextureEffect candyCloudTextureEffect = new CandyCloudTextureEffect(lx);

  lx.addEffect(blurEffect);
  lx.addEffect(colorEffect);
  lx.addEffect(ghostEffect);
  lx.addEffect(scrambleEffect);
  lx.addEffect(staticEffect);
  lx.addEffect(rotationEffect);
  lx.addEffect(spinEffect);
  lx.addEffect(speedEffect);
  lx.addEffect(colorStrobeTextureEffect);
  lx.addEffect(fadeTextureEffect);
  lx.addEffect(acidTripTextureEffect);
  lx.addEffect(candyTextureEffect);
  lx.addEffect(candyCloudTextureEffect);

  effectKnobParameters = new LXListenableNormalizedParameter[] {
    colorEffect.hueShift,
    colorEffect.mono,
    colorEffect.desaturation,
    colorEffect.sharp,
    blurEffect.amount,
    speedEffect.speed,
    spinEffect.spin,
    candyCloudTextureEffect.amount
  };
}

static JSONArray clusterConfig;
static Geometry geometry = new Geometry();

Model model;
P2LX lx;
FadecandyOutput output;
UIChannelFaders uiFaders;
UIMultiDeck uiDeck;
final BasicParameter bgLevel = new BasicParameter("BG", 25, 0, 50);
final BasicParameter dissolveTime = new BasicParameter("DSLV", 400, 50, 1000);
final BasicParameter drumpadVelocity = new BasicParameter("DVEL", 1);
BPMTool bpmTool;
MappingTool mappingTool;
LXAutomationRecorder[] automation = new LXAutomationRecorder[NUM_AUTOMATION];
BooleanParameter[] automationStop = new BooleanParameter[NUM_AUTOMATION]; 
DiscreteParameter automationSlot = new DiscreteParameter("AUTO", NUM_AUTOMATION);
LXListenableNormalizedParameter[] effectKnobParameters;
MidiEngine midiEngine;
SpeedIndependentContainer speedIndependentContainer;

void setup() {
  size(1148, 720, OPENGL);
  frameRate(90); // this will get processing 2 to actually hit around 60
  
  clusterConfig = loadJSONArray(CLUSTER_CONFIG_FILE);
  geometry = new Geometry();
  model = new Model();
  
  lx = new P2LX(this, model);
  lx.engine.addLoopTask(speedIndependentContainer = new SpeedIndependentContainer(lx));
  lx.engine.addParameter(drumpadVelocity);

  configureChannels();

  registerEffects();

  lx.addEffect(mappingTool = new MappingTool(lx));
  lx.engine.addLoopTask(new ModelTransformTask());

  configureBMPTool();

  configureAutomation();

  configureFadeCandyOutput();

  configureUI();

  configureMIDI();
  
  // bad code I know
  // (shouldn't mess with engine internals)
  // maybe need a way to specify a deck shouldn't be focused?
  // essentially this lets us have extra decks for the drumpad
  // patterns without letting them be assigned to channels
  // -kf
  lx.engine.focusedChannel.setRange(NUM_CHANNELS);
  
  // Engine threading
  lx.engine.framesPerSecond.setValue(60);  
  lx.engine.setThreaded(true);
}

/* configureChannels */

void setupChannel(final LXChannel channel, boolean noOpWhenNotRunning) {
  channel.setFaderTransition(new TreesTransition(lx, channel));

  if (noOpWhenNotRunning) {
    channel.enabled.setValue(channel.getFader().getValue() != 0);
    channel.getFader().addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        channel.enabled.setValue(channel.getFader().getValue() != 0);
      }
    });
  }
}

void configureChannels() {
  lx.setPatterns(getPatternListForChannels());
  for (int i = 1; i < NUM_CHANNELS; ++i) {
    lx.engine.addChannel(getPatternListForChannels());
  }
  
  for (LXChannel channel : lx.engine.getChannels()) {
    channel.goIndex(channel.getIndex());
    setupChannel(channel, false);
  }
}

/* configureBMPTool */

void configureBMPTool() {
  bpmTool = new BPMTool(lx, effectKnobParameters);
}

/* configureAutomation */

void configureAutomation() {
  // Example automation message to change master fader
  // {
  //   "message": "master/0.5",
  //   "event": "MESSAGE",
  //   "millis": 0
  // },
  lx.engine.addMessageListener(new LXEngine.MessageListener() {
    public void onMessage(LXEngine engine, String message) {
      if (message.length() > 8 && message.substring(0, 7).equals("master/")) {
        double value = Double.parseDouble(message.substring(7));
        output.brightness.setValue(value);
      }
    }
  });

  // Automation recorders
  for (int i = 0; i < automation.length; ++i) {
    final int ii = i;
    automation[i] = new LXAutomationRecorder(lx.engine);
    lx.engine.addLoopTask(automation[i]);
    automationStop[i] = new BooleanParameter("STOP", false);
    automationStop[i].addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        if (parameter.getValue() > 0) {
          automation[ii].reset();
          automation[ii].armRecord.setValue(false);
        }
      }
    });
  }
}

/* configureMIDI */

void configureMIDI() {
  // MIDI control
  midiEngine = new MidiEngine(effectKnobParameters);
}

/* configureUI */

void configureUI() {
  // UI initialization
  lx.ui.addLayer(new UICameraLayer(lx.ui) {
      protected void beforeDraw() {
        hint(ENABLE_DEPTH_TEST);
        pushMatrix();
        translate(0, 12*FEET, 0);
      }
      protected void afterDraw() {
        popMatrix();
        hint(DISABLE_DEPTH_TEST);
      }  
    }
    .setRadius(90*FEET)
    .setCenter(model.cx, model.cy, model.cz)
    .setTheta(30*PI/180)
    .setPhi(10*PI/180)
    .addComponent(new UITrees())
  );
  lx.ui.addLayer(new UIMapping(lx.ui));
  lx.ui.addLayer(uiFaders = new UIChannelFaders(lx.ui));
  lx.ui.addLayer(new UIEffects(lx.ui, effectKnobParameters));
  lx.ui.addLayer(uiDeck = new UIMultiDeck(lx.ui));
  lx.ui.addLayer(new UILoopRecorder(lx.ui));
  lx.ui.addLayer(new UIMasterBpm(lx.ui, Trees.this.width-144, 4, bpmTool));
}

/* configureFadeCandyOutput */

void configureFadeCandyOutput() {
  int[] clusterOrdering = new int[] { 0, 1, 2, 3, 4, 5, 8, 7, 9, 10, 11, 12, 13, 15, 14, 6 };
  int numCubesInCluster = clusterOrdering.length;
  int numClusters = 48;
  int[] pixelOrder = new int[numClusters * numCubesInCluster];
  for (int cluster = 0; cluster < numClusters; cluster++) {
    for (int cube = 0; cube < numCubesInCluster; cube++) {
      pixelOrder[cluster * numCubesInCluster + cube] = cluster * numCubesInCluster + clusterOrdering[cube];
    }
  }
  try {
    output = new FadecandyOutput(lx, "127.0.0.1", 7890, pixelOrder);
    lx.addOutput(output);
  } catch (Exception e) {
    println(e);
  }
}

void draw() {
  background(#222222);
}

TreesTransition getFaderTransition(LXChannel channel) {
  return (TreesTransition) channel.getFaderTransition();
}

class TreesTransition extends LXTransition {
  
  private final LXChannel channel;
  
  public final DiscreteParameter blendMode = new DiscreteParameter("MODE", 4);
 
  private LXColor.Blend blendType = LXColor.Blend.ADD;
    
  TreesTransition(LX lx, LXChannel channel) {
    super(lx);
    addParameter(blendMode);
    
    this.channel = channel;
    blendMode.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        switch (blendMode.getValuei()) {
        case 0: blendType = LXColor.Blend.ADD; break;
        case 1: blendType = LXColor.Blend.MULTIPLY; break;
        case 2: blendType = LXColor.Blend.LIGHTEST; break;
        case 3: blendType = LXColor.Blend.SUBTRACT; break;
        }
      }
    });
  }
  
  protected void computeBlend(int[] c1, int[] c2, double progress) {
    if (progress == 0) {
      for (int i = 0; i < colors.length; ++i) {
        colors[i] = c1[i];
      }
    } else if (progress == 1) {
      for (int i = 0; i < colors.length; ++i) {
        int color2 = (blendType == LXColor.Blend.SUBTRACT) ? LX.hsb(0, 0, LXColor.b(c2[i])) : c2[i]; 
        colors[i] = LXColor.blend(c1[i], color2, this.blendType);
      }
    } else {
      for (int i = 0; i < colors.length; ++i) {
        int color2 = (blendType == LXColor.Blend.SUBTRACT) ? LX.hsb(0, 0, LXColor.b(c2[i])) : c2[i];
        colors[i] = LXColor.lerp(c1[i], LXColor.blend(c1[i], color2, this.blendType), progress);
      }
    }
  }
}

class BooleanProxyParameter extends BooleanParameter {

  final List<BooleanParameter> parameters = new ArrayList<BooleanParameter>();

  BooleanProxyParameter() {
    super("Proxy", true);
  }

  protected double updateValue(double value) {
    for (BooleanParameter parameter : parameters) {
      parameter.setValue(value);
    }
    return value;
  }
}

