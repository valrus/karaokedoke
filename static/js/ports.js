// { lyrics: LyricPage, scratchId: String, fontName: String} -> SizedLyricPage
app.ports.jsGetSizes.subscribe(function (args) {
    var sizedLyricPage = getSizedLyricPage(args.lyrics, args.scratchId, app.allFonts[args.fontName]);
    app.ports.gotSizes.send(sizedLyricPage);
});


function makeSvgTextElement(font) {
    var svg = document.createElementNS(svgNS, "svg");
    var textElement = document.createElementNS(svgNS, "text");
    var data = document.createTextNode("load this font");
    svg.setAttribute('visibility', 'hidden');
    svg.setAttribute('width', '0');
    svg.setAttribute('height', '0');
    svg.setAttribute('font-family', font);
    svg.setAttribute('font-size', '512px');
    svg.setAttributeNS("http://www.w3.org/2000/xmlns/", "xmlns:xlink", "http://www.w3.org/1999/xlink");

    document.body.appendChild(svg);
    svg.appendChild(textElement);
    textElement.appendChild(data);

    return svg;
}

// List { name: String, path: String } -> Bool
app.ports.jsLoadFonts.subscribe(function(fonts) {
    var fontsLoaded = 0;
    var loaderSvgs = {};
    for (var i = 0; i < fonts.length; i++) {
        fontArgs = fonts[i];
        loaderSvgs[fontArgs.name] = makeSvgTextElement(fontArgs.name);
        opentype.load(fontArgs.path, function(err, font) {
            if (err) {
                alert('Could not load font: ' + err);
                app.ports.loadedFonts.send(false);
            } else {
                app.allFonts[fontArgs.name] = font;
            };
            document.body.removeChild(loaderSvgs[fontArgs.name]);
            fontsLoaded++;
            if (fontsLoaded == fonts.length) {
                app.ports.loadedFonts.send(true);
            }
        });
    };
});

app.ports.jsSetPlayback.subscribe(function (play) {
    console.log('toggle');
    var audio = document.getElementById('audio-player');
    var playing = false;
    if (play) {
        audio.play();
        playing = true;
    }
    else {
        audio.pause();
        playing = false;
    };
    app.ports.playState.send(playing);
});

app.ports.jsSeekTo.subscribe(function (position) {
    console.log(position);
    var audio = document.getElementById('audio-player');
    audio.currentTime = position;
    app.ports.playhead.send(audio.currentTime);
});
