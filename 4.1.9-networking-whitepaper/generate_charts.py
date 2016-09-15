import os
import subprocess
import textwrap

target_r_script = '__generate_charts.r'

with open(target_r_script, 'w') as f:
    f.write('library(lattice)\n')

    for irods_version_array in [['4','1','9']]:
        irods_version = ''.join(irods_version_array)
        irods_version_dotted = '.'.join(irods_version_array)
        setup = textwrap.dedent(
        '''
        #############  {1}  #############

        raw = read.csv("results-{0}-{0}-detail.csv")
        summary(raw)

        # average the runs
        #tmp <- aggregate(seconds ~ GB + delay + tcp_size + parallel_buffer + N, raw, ave)
        #d <- do.call(data.frame, tmp)[,1:6]
        #colnames(d)[6] <- "avg_seconds"
        #summary(d)

        d <- aggregate(raw[,7], raw[,1:5], FUN = median, na.rm=TRUE)
        colnames(d)[6] <- "avg_seconds"
        summary(d)

        d$parallel_buffer <- ordered(d$parallel_buffer, levels = c(4,50,100), labels = c('4MB iRODS Buffer','50MB iRODS Buffer','100MB iRODS Buffer'))
        d$tcp_size <- ordered(d$tcp_size, levels = c('default','big'), labels = c('Default TCP Buffers','Tuned TCP Buffers'))
        d$N <- ordered(d$N, levels = c(1,2,3,4,8,16), labels = c('Streaming','2 Threads','3 Threads','4 Threads','8 Threads','16 Threads'))
        '''.format(irods_version, irods_version_dotted)
        )
        f.write(setup)

        for filesize in [10]:
            draw_plot = textwrap.dedent(
            '''
            # create dataframe for {2}G
            d.{2}G <- subset(d, GB == "{2}")
            # generate and save plot to file
            png(filename="{0}-{0}-{2}GB-detail.png")
            xyplot( avg_seconds ~ delay | parallel_buffer + tcp_size, d.{2}G, groups = N, main = "iRODS {1} - {2}GB file", type = "b", ylab = "Transfer Time (seconds)", xlab = "Network RTT (milliseconds)", auto.key = list(space="top", columns=2, pt.cex=1, cex=.8) )
            dev.off()
            '''.format(irods_version, irods_version_dotted, filesize)
            )
            f.write(draw_plot)

subprocess.call(['Rscript', target_r_script])
