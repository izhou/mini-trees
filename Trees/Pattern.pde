abstract class TSPattern extends LXPattern {
  ParameterTriggerableAdapter parameterTriggerableAdapter;
  String readableName;

  TSPattern(LX lx) {
    super(lx);
  }

  void onTriggerableModeEnabled() {
    getChannel().getFader().setValue(0);
    getChannelFade().setValue(0);
    parameterTriggerableAdapter = new ParameterTriggerableAdapter(getChannelFade());
    parameterTriggerableAdapter.addOutputTriggeredListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        setCallRun(parameter.getValue() != 0);
      }
    });
    setCallRun(false);
  }

  Triggerable getTriggerable() {
    return parameterTriggerableAdapter;
  }

  BasicParameter getChannelFade() {
    return getFaderTransition(getChannel()).fade;
  }

  void setCallRun(boolean callRun) {
    // getChannel().enabled.setValue(callRun);
  }

  boolean getEnabled() {
    return getTriggerable().isTriggered();
  }

  double getVisibility() {
    return getChannel().getFader().getValue();
  }
}

abstract class TSTriggerablePattern extends TSPattern implements Triggerable {

  static final int PATTERN_MODE_PATTERN = 0;
  static final int PATTERN_MODE_TRIGGER = 1; // calls the run loop only when triggered
  static final int PATTERN_MODE_FIRED = 2; // like triggered, but must disable itself when finished
  static final int PATTERN_MODE_CUSTOM = 3; // always calls the run loop

  int patternMode = PATTERN_MODE_TRIGGER;

  boolean triggerableModeEnabled;
  boolean triggered = true;
  double firedTimer = 0;

  TSTriggerablePattern(LX lx) {
    super(lx);
  }

  void onTriggerableModeEnabled() {
    getChannel().getFader().setValue(1);
    if (patternMode == PATTERN_MODE_TRIGGER || patternMode == PATTERN_MODE_FIRED) {
      getChannel().enabled.setValue(false);
    }
    triggerableModeEnabled = true;
    triggered = false;
  }

  Triggerable getTriggerable() {
    return this;
  }

  public boolean isTriggered() {
    return triggered;
  }

  public void onTriggered(float strength) {
    if (patternMode == PATTERN_MODE_TRIGGER || patternMode == PATTERN_MODE_FIRED) {
      getChannel().enabled.setValue(true);
    }
    triggered = true;
    firedTimer = 0;
  }

  public void onRelease() {
    if (patternMode == PATTERN_MODE_TRIGGER) {
      getChannel().enabled.setValue(false);
    }
    triggered = false;
  }

  public void addOutputTriggeredListener(LXParameterListener listener) {

  }
}

