Gson gson = new Gson();
ClientCommunicator clientCommunicator = new ClientCommunicator();
ClientModelUpdater clientModelUpdater;

class AppServer {
  LX lx;

  AppServer(LX lx) {
    this.lx = lx;
  }

  void start() {
    Server server = new Server(Trees.this, 5204);
    clientCommunicator.server = server;

    ServerController serverController = new ServerController();
    clientModelUpdater = new ClientModelUpdater(lx, clientCommunicator);
    ParseClientTask parseClientTask = new ParseClientTask(server, clientModelUpdater, serverController);
    lx.engine.addLoopTask(parseClientTask);
  }
}

class ParseClientTask implements LXLoopTask {
  Server server;
  ClientModelUpdater clientModelUpdater;
  ServerController serverController;

  ParseClientTask(Server server, ClientModelUpdater clientModelUpdater, ServerController serverController) {
    this.server = server;
    this.clientModelUpdater = clientModelUpdater;
    this.serverController = serverController;
  }

  public void loop(double deltaMs) {
    try {
      Client client = server.available();
      if (client == null) return;

      String whatClientSaid = client.readStringUntil('\n');
      if (whatClientSaid == null) return;

      print("Request: " + whatClientSaid);

      Map<String, Object> message;
      try {
        message = gson.fromJson(whatClientSaid.trim(), Map.class);
      } catch (Exception e) {
        println(e);
        return;
      }

      String method = (String)message.get("method");
      Map<String, Object> params = (Map)message.get("params");

      if (method == null) return;
      if (params == null) params = new HashMap<String, Object>();

      if (method.equals("load-model")) {
        clientModelUpdater.sendModel();
      } else if (method.equals("set-pattern-enabled")) {
        String name = (String)params.get("name");
        Boolean enabled = (Boolean)params.get("enabled");
        if (name == null || enabled == null) return;
        serverController.setPatternEnabled(name, enabled);
      } else if (method.equals("set-pattern-strength")) {
        String name = (String)params.get("name");
        Double strength = (Double)params.get("strength");
        if (name == null || strength == null) return;
        serverController.setPatternStrength(name, strength);
      } else if (method.equals("set-effect-enabled")) {
        String name = (String)params.get("name");
        Boolean enabled = (Boolean)params.get("enabled");
        if (name == null || enabled == null) return;

        serverController.setEffectEnabled(name, enabled);
      }
    } catch (Exception e) {
      println(e);
    }
  }
}

class ServerController {
  void setPatternEnabled(String patternName, boolean enabled) {
    for (TSPattern pattern : patterns) {
      if (pattern.getName().equals(patternName)) {
        if (enabled) {
          pattern.getTriggerable().onTriggered(1);
        } else {
          pattern.getTriggerable().onRelease();
        }
      }
    }
  }

  void setPatternStrength(String patternName, double strength) {
    for (TSPattern pattern : patterns) {
      if (pattern.getName().equals(patternName)) {
        pattern.getChannel().getFader().setValue(strength);
      }
    }
  }
  void setEffectEnabled(String effectName, boolean enabled) {
    for (TSEffectController effectController : effectControllers) {
      if (effectController.getName().equals(effectName)) {
        effectController.setEnabled(enabled);
      }
    }
  }
}

class ClientModelUpdater {
  ClientCommunicator communicator;
  LX lx;

  ClientModelUpdater(LX lx, ClientCommunicator communicator) {
    this.communicator = communicator;
  }

  void sendModel() {
    Map<String, Object> returnParams = new HashMap<String, Object>();

    List<Map> channelsParams = new ArrayList<Map>(lx.engine.getChannels().size());
    for (LXChannel channel : lx.engine.getChannels()) {
      Map<String, Object> channelParams = new HashMap<String, Object>();
      channelParams.put("index", channel.getIndex());
      channelParams.put("current-pattern", channel.getActivePattern());
      channelParams.put("visibility", channel.getFader().getValue());

      List<Map> patternsParams = new ArrayList<Map>(channel.getPatterns().size());
      for (int i = 0; i < channel.getPatterns().size(); i++) {
        TSPattern pattern = (TSPattern)channel.getPatterns().get(i);
        Map<String, Object> patternParams = new HashMap<String, Object>();
        patternParams.put("name", pattern.getName());
        patternParams.put("index", i);
        patternsParams.add(patternParams);
      }
      channelParams.put("patterns", patternsParams);

      channelsParams.add(channelParams);
    }
    returnParams.put("patterns", channelsParams);

    List<Map> effectsParams = new ArrayList<Map>(effectControllers.size());
    for (TSEffectController effectController : effectControllers) {
      Map<String, Object> effectParams = new HashMap<String, Object>();
      effectParams.put("name", effectController.getName());
      effectParams.put("enabled", effectController.getEnabled());
      effectsParams.add(effectParams);
    }
    returnParams.put("effects", effectsParams);

    communicator.send("model", returnParams);
  }
}

class ClientCommunicator {
  Server server;

  void send(String method, Map params) {
    Map<String, Object> json = new HashMap<String, Object>();
    json.put("method", method);
    json.put("params", params);
    println("Response: " + gson.toJson(json));
    server.write(gson.toJson(json) + "\r\n");
  }

  void disconnectClient(Client client) {
    client.dispose();
    server.disconnect(client);
  }
}

// Hack because of a bug
// See: https://github.com/processing/processing/issues/2577
void disconnectEvent(Client client) {
  clientCommunicator.disconnectClient(client);
}

