var wavesurfer;


function sendRegion(region) {
    console.log(region);
    console.log({
        id: region.id,
        start: region.start,
        startPixels: region.element.offsetLeft,
        endPixels: region.element.offsetLeft + region.element.offsetWidth
    });
    app.ports.addedRegion.send({
        id: region.id,
        start: region.start,
        startPixels: region.element.offsetLeft,
        endPixels: region.element.offsetLeft + region.element.offsetWidth
    });
}

function setupRegions(regions) {
    console.log('in jsEditorCreateRegions');
    regions.forEach(region => {
        region.resize = false;
        region.color = "rgba(1.0, 0.0, 0.0, 0.8)";
        region.end = Math.min(region.start + 0.2, wavesurfer.getDuration());
        addedRegion = wavesurfer.addRegion(region);
        // I think this isn't necessary?
        sendRegion(addedRegion);
    });
}

function editorInitializeWavesurfer(app, args) {
    console.log("hit initializeWavesurfer in js with " + args.containerId + " and " + args.songUrl);

    wavesurfer = WaveSurfer.create({
        container: '#' + args.containerId,
        vertical: true,
        fillParent: false,
        height: 800,
        barWidth: 5,
        barRadius: 5,
        plugins: [
            WaveSurfer.regions.create({})
        ]
    });

    wavesurfer.on('ready', function () {
        console.log("wavesurfer sending length: " + wavesurfer.getDuration());
        app.ports.gotWaveformLength.send({ length: wavesurfer.getDuration(), error: null });
    });

    wavesurfer.on('error', function(errorString) {
        app.ports.gotWaveformLength.send({ error: errorString, length: null });
    });

    wavesurfer.on('seek', function(proportion) { sendPlayhead(proportion * wavesurfer.getDuration()) });

    wavesurfer.on('audioprocess', sendPlayhead);

    wavesurfer.on('region-updated', function(region) { sendRegion(region); })

    app.ports.jsEditorCreateRegions.subscribe(setupRegions);
    app.ports.jsPlayPause.subscribe(togglePlaying);

    wavesurfer.load(args.songUrl);
    return (wavesurfer !== 'undefined');
}

function destroyWavesurfer() {
    if (wavesurfer != null) {
        app.ports.jsEditorCreateRegions.unsubscribe(setupRegions);
        wavesurfer.unAll();
        wavesurfer.destroy();
    }
}
