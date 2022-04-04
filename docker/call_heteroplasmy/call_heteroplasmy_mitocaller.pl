#!/usr/bin/env perl

### call_heteroplasmy_mitocaller.pl
##################################################################################
# 
# 
### HISTORY
#######################################################################################
# Version               Date                Coder                     Comments
# 0.01                  2017-10-30          Takafumi Yamaguchi        Initial development.
#
###INCLUDES
######################################################################################

use strict;
use warnings;
use Getopt::Long;
use Carp;
use Pod::Usage;
use Path::Class;
use File::Spec;
use File::Basename;
use File::Path qw(make_path);
use Data::Dumper;
#use Log::ProgramInfo;
### COMMAND LINE DEFAULT ARGUMENTS ################################################################
# list of arguments and default values go here as hash key/value pairs
our %opts = (
	normal_table  => undef,
	tumour_table  => undef,
	min_coverage => 100,
	het_fraction => 0.2,
	output  => 'heteroplasmy_call.tsv'
	);

### MAIN CALLER ###################################################################################
my $result = main();
exit($result);

### FUNCTIONS #####################################################################################

### main ##########################################################################################
# Description:
#   Main subroutine for program
# Input Variables:
#   %opts = command line arguments
# Output Variables:
#   N/A

sub main {
	# get the command line arguments
	GetOptions(
		\%opts,
		"help|?",
		"man",
		"normal_table=s"     => \$opts{'normal_table'},
		"tumour_table=s"     => \$opts{'tumour_table'},
		"ascat_stat:s"       => \$opts{'ascat_stat'},
		"min_coverage=s"     => \$opts{'min_coverage'},
		"het_fraction=s"     => \$opts{'het_fraction'},
		"output=s"     => \$opts{'output'}
	) or pod2usage(64);
	
		if ($opts{'help'}) { pod2usage(1) };
		if ($opts{'man'}) { pod2usage(-exitstatus => 0, -verbose => 2) };
	
	while(my ($arg, $value) = each(%opts)){
		if (!($arg=~/\:/) and !defined $value) {
		print "ERROR: Missing argument $arg\n";
		pod2usage(2);
		}
		}

		my ($data, $tumour_purity);
					
		$data = read_table($opts{normal_table}, 'normal', $data);
		$data = read_table($opts{tumour_table}, 'tumour', $data);
		#print header
		open (my $fh_out, '>', $opts{output});

		# Create output for filtered heteroplasmy calls
		my ($base_name, $dir) = fileparse($opts{output});
		my $output_filt = join('_', 'filtered', $base_name);
		$output_filt = File::Spec->catfile($dir, $output_filt);

		open (my $fh_filt_out, '>', $output_filt);

		if($opts{ascat_stat}){
			#open and get purity from ascat stat
			open (my $fh_ascat_stat, $opts{ascat_stat}) or croak "Could not open file '$opts{ascat_stat}'. $!";;

			print "Getting tumour purity from $opts{ascat_stat}\n";

			while(<$fh_ascat_stat>){

				my $line = $_;
				chomp($line);

				next unless($line=~/^rho/);

				my @rho = split /\s/, $line;

				$tumour_purity = $rho[1];

				print "Estimated tumour purity is $tumour_purity\n";
				last;

				}

			close $fh_ascat_stat;
			
			} else {
				print "No ascat stat found and purity estimation will be 1\n";
			}

		#print $fh_out join("\t", 'Position', @samples)."\n";
		my $header = join("\t", 'chr', 'pos', 'ref', 'normal_genotype', 'tumour_genotype', 
			'normal_filtered_depth', 'tumour_filtered_depth',
			'normal_frequency', 'tumour_frequency',
			'alt', 'heteroplasmy_fraction_diff', 'heteroplasmy_fraction_adjusted_diff', 'somatic'
			)."\n";

		print $fh_out $header;
		print $fh_filt_out $header;

		#output heteroplasmy matrix
		foreach my $pos (sort {$a <=> $b} keys %{$data->{normal}}){

			my $hetp;

			if($data->{normal}->{$pos}->{genotype} ne $data->{tumour}->{$pos}->{genotype}){
			# print join("\t", $pos, $data->{normal}->{$pos}->{genotype}, $data->{tumour}->{$pos}->{genotype}, $data->{normal}->{$pos}->{fraction}, $data->{tumour}->{$pos}->{fraction})."\n";        

				$hetp = assign_genotype_fraction($data->{normal}->{$pos}->{genotype}, $data->{normal}->{$pos}->{fraction}, 'normal', $hetp);
				$hetp = assign_genotype_fraction($data->{tumour}->{$pos}->{genotype}, $data->{tumour}->{$pos}->{fraction}, 'tumour', $hetp);

			#print Dumper($hetp);
				#exit;
				foreach my $base ('A', 'T', 'G', 'C'){

					if(!$hetp->{normal}->{$base}){

						$hetp->{normal}->{$base} = 0;
						
						}

					if(!$hetp->{tumour}->{$base}){

						$hetp->{tumour}->{$base} = 0;
						
						}

					### adjust HF using tumour purity ######################################################################################
					$hetp->{tumour_adjusted}->{$base} = get_adjusted_hf($hetp->{normal}->{$base}, $hetp->{tumour}->{$base}, $tumour_purity);

					if(($hetp->{tumour_adjusted}->{$base} - $hetp->{normal}->{$base}) > $opts{het_fraction}){
						
						my $val = ($hetp->{tumour}->{$base} - $hetp->{normal}->{$base});
						my $val_adjusted = ($hetp->{tumour_adjusted}->{$base} - $hetp->{normal}->{$base});
						#print $pos."\t".$base."\t".$hetp->{normal}->{$base}."\t".$hetp->{tumour}->{$base}."\t".$data->{tumour}->{$pos}->{val}."\n";
						$data->{tumour}->{$pos}->{somaticheteroplasmy_binary} = 1; 
						push @{$data->{tumour}->{$pos}->{somaticheteroplasmy_base}}, $base;
						push @{$data->{tumour}->{$pos}->{somaticheteroplasmy_val}}, $val;
						push @{$data->{tumour}->{$pos}->{somaticheteroplasmy_val_adjusted}}, $val_adjusted;
						} 

					}
				}
				
				#In the RSRS (Reconstructed Sapiens Reference Sequence) reference genome, 523, 524 and 3107 are N's used to preserve historical numbering
				#In the rCRS (revised Cambridge Reference Sequence) genome, only 3107 is an N. 523-524 are AC. However these positions are commonly deleted which is why they are not in RSRS. 
				#Position 310, a homopolymer stretch is commonly misaligned, is removed from consideration as well.
				
				if(!$data->{tumour}->{$pos}->{somaticheteroplasmy_binary} or $pos =~m/(^310$|^523$|^524$|^3107$)/ or $data->{normal}->{$pos}->{filt_depth} < $opts{min_coverage} or $data->{tumour}->{$pos}->{filt_depth} < $opts{min_coverage}){
					$data->{tumour}->{$pos}->{somaticheteroplasmy_binary} = 0;
					}

				#most positions have no somatic heteroplasmy
				if(!$data->{tumour}->{$pos}->{somaticheteroplasmy_base}){
					push @{$data->{tumour}->{$pos}->{somaticheteroplasmy_base}}, 'NA';
					push @{$data->{tumour}->{$pos}->{somaticheteroplasmy_val}}, 'NA';
					push @{$data->{tumour}->{$pos}->{somaticheteroplasmy_val_adjusted}}, 'NA';
					}

				my $output = join("\t", $data->{normal}->{$pos}->{chr}, $pos, $data->{normal}->{$pos}->{ref}, 
					$data->{normal}->{$pos}->{genotype}, 
					$data->{tumour}->{$pos}->{genotype}, 
					$data->{normal}->{$pos}->{filt_depth},
					$data->{tumour}->{$pos}->{filt_depth},
					$data->{normal}->{$pos}->{fraction},
					$data->{tumour}->{$pos}->{fraction},
					join(',', @{$data->{tumour}->{$pos}->{somaticheteroplasmy_base}}),
					join(',', @{$data->{tumour}->{$pos}->{somaticheteroplasmy_val}}),
					join(',', @{$data->{tumour}->{$pos}->{somaticheteroplasmy_val_adjusted}}),
					$data->{tumour}->{$pos}->{somaticheteroplasmy_binary}
					)."\n";

				if($data->{tumour}->{$pos}->{somaticheteroplasmy_binary} eq 1){
					print $fh_filt_out $output;
					} 

					print $fh_out $output;
			}
			close ($fh_out);
			close ($fh_filt_out);
			print "Complete!\n";
			return 0;
			}

sub get_adjusted_hf {

	my ($normal_hf, $tumour_hf, $tumour_purity) = @_;

	#force completed ascat results has purity = ?->assume tumour purity = 1
	if(!$tumour_purity or '?' eq $tumour_purity or '0' eq $tumour_purity){
			$tumour_purity = 1;
		}
	#adjust HF based on qpure cellularity. the results should be identifical when cellularity = 1
	my $adjusted_tumour_hf = ($tumour_hf - (1 - $tumour_purity) * $normal_hf)/ $tumour_purity;
	# no HF more than 1 or less than 0
	if($adjusted_tumour_hf > 1){$adjusted_tumour_hf = 1;}
	if($adjusted_tumour_hf < 0){$adjusted_tumour_hf = 0;}

	return($adjusted_tumour_hf);

}

sub assign_genotype_fraction {

	my ($genotypes, $fractions, $type, $hash_ref) = @_;

	my @genotypes = split /\//, $genotypes;
	my @fractions = split /\//, $fractions;

	for(my $i=0; $i < scalar @genotypes; $i++){

		$hash_ref->{$type}->{$genotypes[$i]} = $fractions[$i];

		}

	return($hash_ref);

}

sub read_table {

	my ($file, $sample, $data) = @_;

	print "Processing $file\n";

		open (my $fh_file, "gunzip -c $file |");
		
		my $header = <$fh_file>;

		my $col_idx_tsv = column_map($header);
		
		while(<$fh_file>){

				my $line = $_;
				chomp($line);

				my @fields = split /\t/, $line;

				my $pos = $fields[$col_idx_tsv->{'Pos'}];
				$data->{$sample}->{$pos}->{chr} = $fields[$col_idx_tsv->{'#Chrom'}];
				$data->{$sample}->{$pos}->{ref} = $fields[$col_idx_tsv->{'Ref'}];
				$data->{$sample}->{$pos}->{filt_depth} = $fields[$col_idx_tsv->{'FilteredDepth'}];
				$data->{$sample}->{$pos}->{genotype} = $fields[$col_idx_tsv->{'Genotype'}];
				$data->{$sample}->{$pos}->{fraction} = $fields[$col_idx_tsv->{'AlleleFractions'}];
				
				$data->{$sample}->{$pos}->{ref} =~s/RefBase://;
				$data->{$sample}->{$pos}->{filt_depth} =~s/DepthFilter://;
				$data->{$sample}->{$pos}->{genotype} =~s/Genotype://;
				$data->{$sample}->{$pos}->{fraction} =~s/Frequency://;
			}
		
		close ($fh_file);

		return($data);
		}

sub column_map {

		my ($header) = @_;
		# Instead of a chomp, do a thorough removal of carriage returns, line feeds, and prefixed/suffixed whitespace
		my @header = map {s/^\s+|\s+$|\r|\n//g; $_} split( /\t/, $header );

		# Fetch the column names and do some sanity checks
		my $idx = 0;
		my $col_idx;
		map { my $colname = $_; $col_idx->{$colname} = $idx; ++$idx;} @header;
		
		#show index
		$Data::Dumper::Sortkeys = 1;
		#print Dumper($col_idx);
		#exit;
		return($col_idx);

		}

exit;

__END__

=head1 NAME

generate_heteroplasmy_matrix.pl

=head1 SYNOPSIS

B<generate_heteroplasmy_matrix.pl> [options] [file ...]

	Options:
	--help          brief help message
	--man           full documentation
	--dir           directory to search
=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page.

=item B<--normal>

Normal BAM file.

=item B<--tumour>

Tumour BAM file.

=item B<--ref>

Reference genome in FASTA format.

=item B<--modules>

Comma separated list of environment modules to load (default: Perl-BL).

=back

=head1 DESCRIPTION

B<generate_heteroplasmy_matrix.pl> Generate hetroplasmy fraction matrix

=head1 EXAMPLE

generate_heteroplasmy_matrix.pl --normal normal.bam --tumour tumour.bam --ref reference.fasta

=head1 AUTHOR

Takafumi Yamaguchi  -- Boutros Lab

The Ontario Institute for Cancer Research

=head1 ACKNOWLEDGEMENTS

Paul Boutros, PhD, PI - Boutros Lab
