static class Geometry {

  final static float HEIGHT = 570;
  
  final static float CORNER_RADIUS = 62 * FEET;
  final static float CORNER_DISTANCE = 786;
  
  final static float MIDDLE_RADIUS = 85 * FEET;
  final static float MIDDLE_DISTANCE = 1050; 
  
  final static float VERTICAL_MIDPOINT = 156;
 
  final static float BEAM_SPACING = 42;
  final static int NUM_BEAMS = 11;
  final static float BEAM_WIDTH = 6;

  final float[] heights;
  final float[] distances;

  Geometry() {
    distances = new float[(int) (HEIGHT/BEAM_SPACING + 2)];
    heights = new float[(int) (HEIGHT/BEAM_SPACING + 2)];
    for (int i = 0; i < heights.length; ++i) {
      heights[i] = min(HEIGHT, i * BEAM_SPACING);
      distances[i] = distanceFromCenter(heights[i]);
    }
  }
  
  float distanceFromCenter(float atHeight) {
    float oppositeLeg = VERTICAL_MIDPOINT - atHeight;
    float angle = asin(oppositeLeg / MIDDLE_RADIUS);
    float adjacentLeg = MIDDLE_RADIUS * cos(angle);
    return MIDDLE_DISTANCE - adjacentLeg;  
  }
  
  float angleFromAxis(float atHeight) {
    // This is some shitty trig. I am sure there
    // is a simpler way but it wasn't occuring to me.
    float x1 = MIDDLE_DISTANCE - distanceFromCenter(atHeight);
    float a1 = acos(x1 / MIDDLE_RADIUS); 
    
    float r = MIDDLE_RADIUS;
    float y = Cluster.BRACE_LENGTH / 2;
    float a = asin(y/r);
    float a2 = a1 - 2*a;
    
    float x2 = cos(a2) * MIDDLE_RADIUS;
    
    return asin((x2-x1) /Cluster.BRACE_LENGTH); 
  }
}

static class Model extends LXModel {
  
  final List<Tree> trees;
  final List<Cluster> clusters;
  final List<Cube> cubes;
    
  Model() {
    super(new Fixture());
    Fixture f = (Fixture) this.fixtures.get(0);
    this.trees = Collections.unmodifiableList(f.trees);
    
    List<Cluster> _clusters = new ArrayList<Cluster>();
    for (Tree tree : this.trees) {
      for (Cluster cluster : tree.clusters) {
        _clusters.add(cluster);
      }
    }
    this.clusters = Collections.unmodifiableList(_clusters);
    
    List<Cube> _cubes = new ArrayList<Cube>();
    for (Cluster cluster : this.clusters) {
      for (Cube cube : cluster.cubes) {
        _cubes.add(cube);
      }
    }
    this.cubes = Collections.unmodifiableList(_cubes);
  }
  
  static class Fixture extends LXAbstractFixture {
    
    final List<Tree> trees = new ArrayList<Tree>();
    
    Fixture() {
      int treeIndex = 0;
      for (float[] treePosition : TREE_POSITIONS) {
        trees.add(new Tree(treeIndex++, treePosition[0], treePosition[1], treePosition[2]));
      }
      for (Tree tree : trees) {
        for (LXPoint p : tree.points) {
          points.add(p);
        }
      }
    }
  }
}

static class Tree extends LXModel {
  
  final List<Cluster> clusters;
  
  final float x;
  final float z;
  final float ry;
  
  Tree(int treeIndex, float x, float z, float ry) {
    super(new Fixture(treeIndex, x, z, ry));
    Fixture f = (Fixture)this.fixtures.get(0);
    this.clusters = Collections.unmodifiableList(f.clusters);
    this.x = x;
    this.z = z;
    this.ry = ry;
  }
  
  static class Fixture extends LXAbstractFixture {
    
    final List<Cluster> clusters = new ArrayList<Cluster>();
    
    Fixture(int treeIndex, float x, float z, float ry) {
      PVector treeCenter = new PVector(x, 0, z);
      LXTransform t = new LXTransform();
      t.translate(x, 0, z);
      t.rotateY(ry * PI / 180);
      
      for (CP cp : CLUSTER_POSITIONS) {
        if (cp.treeIndex == treeIndex) {
          t.push();
          float cry = 0;
          switch (cp.face) {
            // Could be math, but this way it's readable!
            case FRONT: case FRONT_RIGHT:                  break;
            case RIGHT: case REAR_RIGHT:  cry = HALF_PI;   break;
            case REAR:  case REAR_LEFT:   cry = PI;        break;
            case LEFT:  case FRONT_LEFT:  cry = 3*HALF_PI; break;
          }
          t.rotateY(cry);
          t.translate(cp.offset, geometry.heights[cp.level] + cp.mountPoint, -geometry.distances[cp.level]);
          
          switch (cp.face) {
            case FRONT_RIGHT:
            case REAR_RIGHT:
            case REAR_LEFT:
            case FRONT_LEFT:
              t.translate(geometry.distances[cp.level], 0, 0);
              t.rotateY(QUARTER_PI);
              cry += QUARTER_PI;
              break;
          }
          clusters.add(new Cluster(treeCenter, t, cry*180/PI, 180/PI*geometry.angleFromAxis(t.y())));
          t.pop();
        }
      }
      
      // Mock clusters algorithm
      /*
      for (int y = 3; y < 10; ++y) {
        for (int i = 0; i < 4; ++i) {
          float distance = geometry.distances[y];
          t.push();
          t.translate(0, geometry.heights[y], -distance - 1*FEET);
          if (y < 6) {
            t.translate(((y % 2) == 0) ? (-distance/2) : (distance/2), 0, 0);
            clusters.add(new Cluster(treeCenter, t.x(), t.y(), t.z(), ry + i*90));
          } else {
            if ((y % 2) == 0) t.translate(distance/4., 0, 0);
            t.translate(-distance/2, 0, 0);
            clusters.add(new Cluster(treeCenter, t.x(), t.y(), t.z(), ry + i*90));
            t.translate(distance, 0, 0);
            clusters.add(new Cluster(treeCenter, t.x(), t.y(), t.z(), ry + i*90));
          }
          t.pop();
          t.rotateY(PI/2);
        }
      }
      */

      for (Cluster cluster : this.clusters) {
        for (LXPoint p : cluster.points) {
          this.points.add(p);
        }
      }
    }
  }
}

static class Cluster extends LXModel {
  
  public final static float BRACE_LENGTH = 62;
  
  public final static int LARGE_CUBES_PER_CLUSTER = 3;
  public final static int SMALL_CUBES_PER_CLUSTER = 13;
  
  public final static int PIXELS_PER_CLUSTER =
    LARGE_CUBES_PER_CLUSTER * Cube.PIXELS_PER_LARGE_CUBE +
    SMALL_CUBES_PER_CLUSTER * Cube.PIXELS_PER_SMALL_CUBE;
  
  final List<Cube> cubes;
  
  final float x, y, z, rx, ry;
  
  Cluster(PVector treeCenter, LXTransform transform, float ry) {
    this(treeCenter, transform, ry, 0);
  }
  
  Cluster(PVector treeCenter, LXTransform transform, float ry, float rx) {
    super(new Fixture(treeCenter, transform, ry, rx));
    Fixture f = (Fixture) this.fixtures.get(0);
    this.cubes = Collections.unmodifiableList(f.cubes);
    this.x = transform.x();
    this.y = transform.y();
    this.z = transform.z();
    this.ry = ry;
    this.rx = rx;
  }
  
  static class Fixture extends LXAbstractFixture {

    final List<Cube> cubes;
    
    Fixture(PVector treeCenter, LXTransform transform, float ry, float rx) {
      transform.push();
      transform.rotateY(ry * PI / 180);
      transform.rotateX(rx * PI / 180);
      this.cubes = Arrays.asList(new Cube[] {
        new Cube( 0, treeCenter, transform, Cube.SMALL,   -7, -98, -10,  -5,  18, -18),
        new Cube( 1, treeCenter, transform, Cube.SMALL,   -4, -87,  -9,  -3,  20, -20),
        new Cube( 2, treeCenter, transform, Cube.SMALL,    1, -78,  -8,  10,  30,   5),        
        new Cube( 3, treeCenter, transform, Cube.MEDIUM,  -6, -70, -10,  -3,  20,   0),        
        new Cube( 4, treeCenter, transform, Cube.MEDIUM,   8, -65, -10,   0, -20,  -5),
        new Cube( 5, treeCenter, transform, Cube.GIANT,   -6, -51,  -9,   0,  -5, -30),
        new Cube( 6, treeCenter, transform, Cube.SMALL,    3,   1, -16, -10,   0,  20),
        new Cube( 7, treeCenter, transform, Cube.SMALL,  -22, -44, -11,  -5,   0,  15),
        new Cube( 8, treeCenter, transform, Cube.SMALL,    8, -47, -13, -10,   0, -45),
        new Cube( 9, treeCenter, transform, Cube.MEDIUM, -12, -33,  -8, -10,   0,   8),
        new Cube(10, treeCenter, transform, Cube.LARGE,    4, -33,  -8,   0,  10, -15),
        new Cube(11, treeCenter, transform, Cube.SMALL,  -18, -22,  -7, -10,   0,  45),        
        new Cube(12, treeCenter, transform, Cube.LARGE,   -4, -16,  -9,   0,   0,  -5),
        new Cube(13, treeCenter, transform, Cube.MEDIUM,  12, -17,  -9,   5, -20,   0),
        new Cube(14, treeCenter, transform, Cube.SMALL,    8,  -5,  -8,  -5,  10, -45),
        new Cube(15, treeCenter, transform, Cube.SMALL,   -3,  -2,  -7, -10, -10, -50),
      });
      for (Cube cube : this.cubes) {
        for (LXPoint p : cube.points) {
          this.points.add(p);
        }
      }
      transform.pop();
    }
  }
}

static class Cube extends LXModel {

  public static final int PIXELS_PER_SMALL_CUBE = 6;
  public static final int PIXELS_PER_LARGE_CUBE = 12;
  
  public static final float SMALL = 8;
  public static final float MEDIUM = 12;
  public static final float LARGE = 16;
  public static final float GIANT = 17.5;
  
  final int index;
  final int clusterPosition;
  final float size;
  final float x, y, z;
  final float rx, ry, rz;
  final float lx, ly, lz;
  final float tx, ty, tz;
  final float theta;

  Cube(int clusterPosition, PVector treeCenter, LXTransform transform, float size, float x, float y, float z, float rx, float ry, float rz) {
    super(Arrays.asList(new LXPoint[] {
      new LXPoint(transform.x() + x, transform.y() + y, transform.z() + z)
    }));
    
    transform.push();
    transform.translate(x, y, z);
    transform.rotateX(rx);
    transform.rotateY(ry);
    transform.rotateZ(rz);
    
    this.index = this.points.get(0).index;
    this.clusterPosition = clusterPosition;
    this.size = size;
    this.rx = rx;
    this.ry = ry;
    this.rz = rz;
    this.lx = x;
    this.ly = y;
    this.lz = z;
    this.tx = x - treeCenter.x;
    this.ty = y - treeCenter.y;
    this.tz = z - treeCenter.z;
    this.x = transform.x();
    this.y = transform.y();
    this.z = transform.z();

    this.theta = 180 + 180/PI*atan2(this.z - treeCenter.z, this.x - treeCenter.x);
    
    transform.pop();
  }
}
