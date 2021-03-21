function sendPlayhead(time) {
    app.ports.movedPlayhead.send(time);
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

function playerInitializeWavesurfer(app, args) {
    console.log("hit initializePlayerWavesurfer in js with " + args.containerId + " and " + args.songUrl);

    wavesurfer = WaveSurfer.create({
        container: '#' + args.containerId,
        fillParent: true,
        height: 80,
        barWidth: 5,
        barRadius: 5
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

    app.ports.jsPlayPause.subscribe(togglePlaying);

    wavesurfer.load(args.songUrl);
    return (wavesurfer !== 'undefined');
}
