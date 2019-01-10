import toxi.geom.*;
import toxi.geom.mesh2d.*;

class TSPArt {
  
  final int N_OPTIMIZACIONES_PATH = 1000;
  final int N_GENERACIONES = 5;
  final int MAX_PARTICLES = 4000;

  boolean reInitiallizeArray;
  boolean pausemode;
  boolean fileLoaded;
  boolean saveNow;
  boolean fillingCircles;
  boolean errorDisp = false;
  boolean invertImg;
  boolean fileModeTSP;
  boolean tempShowCells;
  boolean showBG, showPath, showCells;
  boolean voronoiCalculated;

  Vec2D[] particles;
  int[] particleRoute;
  int generation;
  int particleRouteLength;
  int vorPointsAdded;
  int routeStep;
  int cellsTotal, cellsCalculated, cellsCalculatedLast;
  int cellBuffer = 100;

  int borderWidth = 6;
  float lowBorderX = borderWidth; //mainwidth*0.01;
  float hiBorderX; //mainwidth*0.98;
  float lowBorderY = borderWidth; // mainheight*0.01;
  float hiBorderY; //mainheight*0.98;

  PImage img, imgload, imgblur;
  Voronoi voronoi;

  float cutoff = 0;
  float minDotSize = 1.75;
  float maxDotSize;
  float dotSizeFactor = 4;

  Polygon2D regionList[];
  PolygonClipper2D clip;

  PImage img_parameter;
  
  String nombreFichero;


  TSPArt(PImage image, String nombreFichero) {
    this.nombreFichero = nombreFichero;
    this.img_parameter = image;
    hiBorderX = img_parameter.width - borderWidth;
    hiBorderY = img_parameter.height - borderWidth;
  }

  void process() {
    //Calculo del camino
    stippleGen();
    stippleGenProcess();
  }


  void stippleGen() {
    borderWidth = 6;

    lowBorderX = borderWidth; //mainwidth*0.01;
    hiBorderX = img_parameter.width *0.98;
    lowBorderY = borderWidth; // mainheight*0.01;
    hiBorderY = img_parameter.height*0.98;

    Rect rect = new Rect(lowBorderX, lowBorderY, img_parameter.width - 2 * borderWidth, img_parameter.height - 2 * borderWidth);
    clip = new SutherlandHodgemanClipper(rect);
    MainArraySetup();   // Main particle array setup

    showPath = true;
    invertImg = false;
  }

  void MainArraySetup() {
    // Main particle array initialization (to be called whenever necessary):
    LoadImageAndScale(img_parameter);

    particles = new Vec2D[MAX_PARTICLES];

    // Fill array by "rejection sampling"
    int  i = 0;
    while (i < MAX_PARTICLES) {
      float fx = lowBorderX + random(hiBorderX - lowBorderX);
      float fy = lowBorderY + random(hiBorderY - lowBorderY);

      float p = brightness(imgblur.pixels[ floor(fy)*imgblur.width + floor(fx) ])/255; 
      // OK to use simple floor_ rounding here, because  this is a one-time operation,
      // creating the initial distribution that will be iterated.

      if (invertImg) {
        p =  1 - p;
      }

      if (random(1) >= p ) {
        Vec2D p1 = new Vec2D(fx, fy);
        particles[i] = p1;
        i++;
      }
    }
    particleRouteLength = 0;
    generation = 0;
    routeStep = 0;
    voronoiCalculated = false;
    cellsCalculated = 0;
    vorPointsAdded = 0;
    voronoi = new Voronoi();  // Erase mesh
    tempShowCells = true;
    fileModeTSP = false;
  }


  void LoadImageAndScale(PImage imgload) {
    int tempx = 0;
    int tempy = 0;

    img = createImage(imgload.width, imgload.height, RGB);
    imgblur = createImage(imgload.width, imgload.height, RGB);

    img.loadPixels();


    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = color(invertImg ? 0 : 255);
    }

    img.updatePixels();

    img.copy(imgload, 0, 0, imgload.width, imgload.height, tempx, tempy, imgload.width, imgload.height);

    imgblur.copy(img, 0, 0, img.width, img.height, 0, 0, img.width, img.height);

    // Low-level blur filter to elminate pixel-to-pixel noise artifacts.
    imgblur.filter(BLUR, 1);
    imgblur.loadPixels();
  }


  void stippleGenProcess() {
    while (generation <= N_GENERACIONES) {
      doPhysics();
    }
    /*
    Llamada innecesaria
    if (!voronoiCalculated) {
      optimizePlotPath();
    }
    */
    println("Optimizanado el trazo");
    for (int i = 0; i < N_OPTIMIZACIONES_PATH; i++) {
      optimizePlotPath();
    }
    guardarSVG();
  }

  void optimizePlotPath() {
    int temp;
    // Calculate and show "optimized" plotting path, beneath points.
    Vec2D p1;

    if (routeStep == 0) {
      float cutoffScaled = 1 - cutoff;
      // Begin process of optimizing plotting route, by flagging particles that will be shown.

      particleRouteLength = 0;

      boolean particleRouteTemp[] = new boolean[MAX_PARTICLES];

      for (int i = 0; i < MAX_PARTICLES; ++i) {
        particleRouteTemp[i] = false;

        int px = (int) particles[i].x;
        int py = (int) particles[i].y;

        if ((px >= imgblur.width) || (py >= imgblur.height) || (px < 0) || (py < 0)) {
          continue;
        }

        float v = (brightness(imgblur.pixels[py * imgblur.width + px])) / 255;

        if (invertImg) {
          v = 1 - v;
        }

        if (v < cutoffScaled) {
          particleRouteTemp[i] = true;
          particleRouteLength++;
        }
      }

      particleRoute = new int[particleRouteLength];
      int tempCounter = 0;
      for (int i = 0; i < MAX_PARTICLES; ++i) {
        if (particleRouteTemp[i]) {
          particleRoute[tempCounter] = i;
          tempCounter++;
        }
      }
      // These are the ONLY points to be drawn in the tour.
    }

    if (routeStep < (particleRouteLength - 2)) {
      // Nearest neighbor ("Simple, Greedy") algorithm path optimization:

      int StopPoint = routeStep + 1000; // 1000 steps per frame displayed; you can edit this number!

      if (StopPoint > (particleRouteLength - 1)) {
        StopPoint = particleRouteLength - 1;
      }

      for (int i = routeStep; i < StopPoint; ++i) {
        p1 = particles[particleRoute[routeStep]];
        int ClosestParticle = 0;
        float  distMin = Float.MAX_VALUE;

        for (int j = routeStep + 1; j < (particleRouteLength - 1); ++j) {
          Vec2D p2 = particles[particleRoute[j]];

          float  dx = p1.x - p2.x;
          float  dy = p1.y - p2.y;
          float  distance = (float) (dx*dx+dy*dy);  // Only looking for closest; do not need sqrt factor!

          if (distance < distMin) {
            ClosestParticle = j;
            distMin = distance;
          }
        }

        temp = particleRoute[routeStep + 1];
        // p1 = particles[particleRoute[routeStep + 1]];
        particleRoute[routeStep + 1] = particleRoute[ClosestParticle];
        particleRoute[ClosestParticle] = temp;

        if (routeStep < (particleRouteLength - 1)) {
          routeStep++;
        } else {
          println("Now optimizing plot path" );
        }
      }
    } else {     // Initial routing is complete
      // 2-opt heuristic optimization:
      // Identify a pair of edges that would become shorter by reversing part of the tour.

      for (int i = 0; i < 90000; ++i) {   // 1000 tests per frame; you can edit this number.
        int indexA = floor(random(particleRouteLength - 1));
        int indexB = floor(random(particleRouteLength - 1));

        if (Math.abs(indexA  - indexB) < 2) {
          continue;
        }

        if (indexB < indexA) { // swap A, B.
          temp = indexB;
          indexB = indexA;
          indexA = temp;
        }

        Vec2D a0 = particles[particleRoute[indexA]];
        Vec2D a1 = particles[particleRoute[indexA + 1]];
        Vec2D b0 = particles[particleRoute[indexB]];
        Vec2D b1 = particles[particleRoute[indexB + 1]];

        // Original distance:
        float  dx = a0.x - a1.x;
        float  dy = a0.y - a1.y;
        float  distance = (float)(dx*dx+dy*dy);  // Only a comparison; do not need sqrt factor!
        dx = b0.x - b1.x;
        dy = b0.y - b1.y;
        distance += (float)(dx*dx+dy*dy);  //  Only a comparison; do not need sqrt factor!

        // Possible shorter distance?
        dx = a0.x - b0.x;
        dy = a0.y - b0.y;
        float distance2 = (float)(dx*dx+dy*dy);  //  Only a comparison; do not need sqrt factor! 
        dx = a1.x - b1.x;
        dy = a1.y - b1.y;
        distance2 += (float)(dx*dx+dy*dy);  // Only a comparison; do not need sqrt factor! 

        if (distance2 < distance) {
          // Reverse tour between a1 and b0.

          int indexhigh = indexB;
          int indexlow = indexA + 1;

          // println("Shorten!" + frameRate );

          while (indexhigh > indexlow) {
            temp = particleRoute[indexlow];
            particleRoute[indexlow] = particleRoute[indexhigh];
            particleRoute[indexhigh] = temp;

            indexhigh--;
            indexlow++;
          }
        }
      }
    }
  }

  void guardarSVG() {
    println("Saving SVG File");

    String[] fileOutput = loadStrings("header.txt");

    String rowTemp;

    float SVGscale = (800.0 / (float) img_parameter.height);
    int xOffset = (int)(1600 - (SVGscale * img_parameter.width / 2));
    int yOffset = (int)(400 - (SVGscale * img_parameter.height / 2));

    // Path header::
    rowTemp = "<path style=\"fill:none;stroke:black;stroke-width:2px;stroke-linejoin:round;stroke-linecap:round;\" d=\"M ";
    fileOutput = append(fileOutput, rowTemp);

    println(" particleRouteLength : " + particleRouteLength);
    for (int i = 0; i < particleRouteLength; ++i) {
      Vec2D p1 = particles[particleRoute[i]];

      float xTemp = SVGscale * p1.x + xOffset;
      float yTemp = SVGscale * p1.y + yOffset;
      rowTemp = xTemp + " " + yTemp + "\r";
      fileOutput = append(fileOutput, rowTemp);
    }
    fileOutput = append(fileOutput, "\" />"); // End path description

    // SVG footer:
    fileOutput = append(fileOutput, "</g></g></svg>");
    saveStrings(nombreFichero, fileOutput);
    println(" - FIN: HE GENERADO EL SVG");
  }

  void doPhysics() {   // Iterative relaxation via weighted Lloyd's algorithm.
    int temp;

    if (!voronoiCalculated) {
      // Part I: Calculate voronoi cell diagram of the points.

      //println("Calculating Voronoi diagram ");

      // float millisBaseline = millis();  // Baseline for timing studies
      // println("Baseline.  Time = " + (millis() - millisBaseline) );

      if (vorPointsAdded == 0) {
        voronoi = new Voronoi();  // Erase mesh
      }

      temp = vorPointsAdded + 500;   // This line: VoronoiPointsPerPass  (Feel free to edit this number.)
      if (temp > MAX_PARTICLES) {
        temp = MAX_PARTICLES;
      }

      for (int i = vorPointsAdded; i < temp; i++) {
        // Optional, for diagnostics:::
        //println("particles[i].x, particles[i].y " + particles[i].x + ", " + particles[i].y );

        voronoi.addPoint(new Vec2D(particles[i].x, particles[i].y ));
        vorPointsAdded++;
      }

      if (vorPointsAdded >= MAX_PARTICLES) {
        // println("Points added.  Time = " + (millis() - millisBaseline) );

        cellsTotal = voronoi.getRegions().size();
        vorPointsAdded = 0;
        cellsCalculated = 0;
        cellsCalculatedLast = 0;

        regionList = new Polygon2D[cellsTotal];

        int i = 0;
        for (Polygon2D poly : voronoi.getRegions()) {
          regionList[i++] = poly;  // Build array of polygons
        }
        voronoiCalculated = true;
      }
    } else {    // Part II: Calculate weighted centroids of cells.
      //  float millisBaseline = millis();
      //  println("fps = " + frameRate );

      //println("Calculating weighted centroids");

      temp = cellsCalculated + 500;   // This line: CentroidsPerPass  (Feel free to edit this number.)
      // Higher values give slightly faster computation, but a less responsive GUI.
      // Default value: 500

      // Time/frame @ 100: 2.07 @ 50 frames in
      // Time/frame @ 200: 1.575 @ 50
      // Time/frame @ 500: 1.44 @ 50

      if (temp > cellsTotal) {
        temp = cellsTotal;
      }

      for (int i=cellsCalculated; i< temp; i++) {
        float xMax = 0;
        float xMin = img_parameter.width;
        float yMax = 0;
        float yMin = img_parameter.height;
        float xt, yt;

        Polygon2D region = clip.clipPolygon(regionList[i]);

        for (Vec2D v : region.vertices) {
          xt = v.x;
          yt = v.y;

          if (xt < xMin) xMin = xt;
          if (xt > xMax) xMax = xt;
          if (yt < yMin) yMin = yt;
          if (yt > yMax) yMax = yt;
        }

        float xDiff = xMax - xMin;
        float yDiff = yMax - yMin;
        float maxSize = max(xDiff, yDiff);
        float minSize = min(xDiff, yDiff);

        float scaleFactor = 1.0;

        // Maximum voronoi cell extent should be between
        // cellBuffer/2 and cellBuffer in size.

        while (maxSize > cellBuffer) {
          scaleFactor *= 0.5;
          maxSize *= 0.5;
        }


        while (maxSize < (cellBuffer / 2)) {
          if (maxSize == Float.NEGATIVE_INFINITY) {
            println("------- xMin : " + xMin);
            println("------- xMax : " + xMax);
            println("------- yMax : " + yMax);
            println("------- yMax : " + yMax);
            // delay(1000);
          }
          scaleFactor *= 2;
          maxSize *= 2;
          //println(maxSize);
        }

        if ((minSize * scaleFactor) > (cellBuffer/2)) {
          // Special correction for objects of near-unity (square-like) aspect ratio,
          // which have larger area *and* where it is less essential to find the exact centroid:
          scaleFactor *= 0.5;
        }

        float StepSize = (1/scaleFactor);

        float xSum = 0;
        float ySum = 0;
        float dSum = 0;
        float PicDensity = 1.0;

        if (invertImg) {
          for (float x=xMin; x<=xMax; x += StepSize) {
            for (float y=yMin; y<=yMax; y += StepSize) {
              Vec2D p0 = new Vec2D(x, y);
              if (region.containsPoint(p0)) {
                // Thanks to polygon clipping, NO vertices will be beyond the sides of imgblur.
                PicDensity = 0.001 + (brightness(imgblur.pixels[ round(y)*imgblur.width + round(x) ]));

                xSum += PicDensity * x;
                ySum += PicDensity * y;
                dSum += PicDensity;
              }
            }
          }
        } else {
          for (float x=xMin; x<=xMax; x += StepSize) {
            for (float y=yMin; y<=yMax; y += StepSize) {
              Vec2D p0 = new Vec2D(x, y);
              if (region.containsPoint(p0)) {
                // Thanks to polygon clipping, NO vertices will be beyond the sides of imgblur.
                PicDensity = 255.001 - (brightness(imgblur.pixels[ round(y)*imgblur.width + round(x) ]));

                xSum += PicDensity * x;
                ySum += PicDensity * y;
                dSum += PicDensity;
              }
            }
          }
        }

        if (dSum > 0) {
          xSum /= dSum;
          ySum /= dSum;
        }

        Vec2D centr;

        float xTemp = xSum;
        float yTemp = ySum;

        if ((xTemp <= lowBorderX) || (xTemp >= hiBorderX) || (yTemp <= lowBorderY) || (yTemp >= hiBorderY)) {
          // If new centroid is computed to be outside the visible region, use the geometric centroid instead.
          // This will help to prevent runaway points due to numerical artifacts.
          centr = region.getCentroid();
          xTemp = centr.x;
          yTemp = centr.y;

          // Enforce sides, if absolutely necessary:  (Failure to do so *will* cause a crash, eventually.)

          if (xTemp <= lowBorderX) xTemp = lowBorderX + 1;
          if (xTemp >= hiBorderX)  xTemp = hiBorderX - 1;
          if (yTemp <= lowBorderY) yTemp = lowBorderY + 1;
          if (yTemp >= hiBorderY)  yTemp = hiBorderY - 1;
        }

        particles[i].x = xTemp;
        particles[i].y = yTemp;

        cellsCalculated++;
      }

      //  println("cellsCalculated = " + cellsCalculated );
      //  println("cellsTotal = " + cellsTotal );

      if (cellsCalculated >= cellsTotal) {
        voronoiCalculated = false;
        generation++;
        println("Generation = " + generation );
      }
    }
  }
}
