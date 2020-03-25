var wavesurfer;

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
    wavesurfer.load(args.songUrl);
    return (wavesurfer !== 'undefined');
}
