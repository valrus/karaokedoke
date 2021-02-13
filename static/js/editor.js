var wavesurfer;

function setupRegions(regions) {
    console.log('in jsEditorCreateRegions');
    regions.forEach(region => { wavesurfer.addRegion(region); console.log(region) });
}

function movePlayhead(time) {
    app.ports.movePlayhead.send(time);
}

function togglePlaying(currentlyPlaying) {
    if (currentlyPlaying) {
        wavesurfer.pause();
    }
    else {
        wavesurfer.play();
    }
    app.ports.changedPlaystate.send(wavesurfer.isPlaying());
}

function initializeWavesurfer(app, args) {
    console.log("hit initializeWavesurfer in js with " + args.containerId + " and " + args.songUrl);
    wavesurfer = WaveSurfer.create({
        container: '#' + args.containerId,
        plugins: [
            WaveSurfer.regions.create({})
        ]
    });
    wavesurfer.on('ready', function () {
        app.ports.gotWaveform.send({ success: true, error: '' });
    });
    wavesurfer.on('error', function(errorString) {
        app.ports.gotWaveform.send({ success: false, error: errorString });
    });
    wavesurfer.on('seek', function(proportion) { movePlayhead(proportion * wavesurfer.getDuration()) });
    wavesurfer.on('audioprocess', movePlayhead);

    app.ports.jsEditorCreateRegions.subscribe(setupRegions);
    app.ports.jsEditorPlayPause.subscribe(togglePlaying);

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
