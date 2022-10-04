

ls -1d */.git | perl -ne 'm|([^/]+)| ; print "$1\n" ' | while read -r line ; do
    cd $line ;
    git log --cherry-pick --right-only --no-merges --pretty=format:"%H;%as;%at;x;%aL;%s"  | perl -ne 'chomp; ($a) = m|([A-Za-z]+-\d{1,6})\D|; if ( $a ) { s|;x;|;$a;|; @a = split(/;/,$_,6); $a[5] =~ s|"||gs; $a[5] =~ s|;|,|gs;  printf "%s\n",  join( ";",$ARGV[0],@a )  } ' -- - $line
    cd .. ;
done

# 

