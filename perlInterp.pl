#!/usr/bin/perl
use Class::Struct;
use Scalar::Util;
use strict;  
use Data::Dumper;

#*********************************************************
#FUNCTION DEFS
#*********************************************************
package numC;

  sub new {
      my ($class, $value) = @_;
      return bless { value => $value }, $class;
    }

  sub interp {
      my $self = shift;
      my $num = $self->{value};

      #check if number
      if ($num eq  $num+0){
        return $num;
      }else{
        return "NaN";
      }
  }

  sub subst {
      my $self = shift;
      my $num = $self->{value};

      #check if number
      if ($num eq  $num+0){

        return numC->new($num);
      }else{
        return "NaN";
      }
  }

package idC;

  sub new {
      my ($class, $id) = @_;
      return bless { id => $id }, $class;
    }

  sub interp {
      my $self = shift;
      my $id = $self->{id};

      #check if idV
      if($id eq $id+0){ #is number
        return "Not an ID (number)"
      }elsif($id =~ /^[a-zA-Z]+$/){ #contains only letters
        return $id;
      }else{
        return "Not an ID";
      }
  }

  sub subst {
      my $self = shift;
      my $id = $self->{id};
      my $from = shift;
      my $to = shift;


      #check if idV
      if($id eq $id+0){#is number
        return "Not an ID (number)"
      }elsif($id =~ /^[a-zA-Z]+$/){#contains only letters
        if($id eq $from){#matches id
          return $to;
        }else{ #doesn't match id
          return idC->new($id);
        }
      }else{#not an id
        return "Not an ID";
      }
  }


package plusC;

  use base ("numC", "idC");

  sub new {
      my ($class, $lhs, $rhs) = @_;
      return bless { lhs => $lhs, rhs => $rhs }, $class;
    }

  sub interp {
      my $self = shift;
      my $lhs = $self->{lhs};
      my $rhs = $self->{rhs};
     
      my $lhsVal = $lhs->interp();

      my $rhsVal = $rhs->interp();

    return $lhsVal + $rhsVal;
  }

  sub subst {
    my $self = shift;
    my $lhs = $self->{lhs};
    my $lhsVal = $lhs->interp();
    my $rhs = $self->{rhs};
    my $rhsVal = $rhs->interp();
    my $from = shift;
    my $to = shift;

    

    if($lhsVal ne $lhsVal+0){ #check if lhs is number, if so move on to rhs
      #subst if idc (letters only)
      if($lhsVal =~ /^[a-zA-Z]+$/){
        $lhs = $lhs->subst($from, $to);
        $self->{lhs} = $lhs;
      }else{
        #else subst on body
        $lhs = $from->subst();
        $self->{lhs} = $lhs;
      }
    }

    if($rhsVal ne $rhsVal+0){ #check if rhs is number, if so move on to rhs
      #subst if idc (letters only)
      if($rhsVal =~ /^[a-zA-Z]+$/){
        $rhs = $rhs->subst($from, $to);
        $self->{rhs} = $rhs;
      }else{
        #else subst on body
        $rhs = $from->subst();
        $self->{rhs} = $rhs;
      }
    }

    return plusC->new($lhs, $rhs);
  }

package multC;

    use base ("numC", "idC");

  sub new {
      my ($class, $lhs, $rhs) = @_;
      return bless { lhs => $lhs, rhs => $rhs }, $class;
    }

  sub interp {
      my $self = shift;
      my $lhs = $self->{lhs};
      my $rhs = $self->{rhs};
     
      my $lhsVal = $lhs->interp();

      my $rhsVal = $rhs->interp();

    return $lhsVal * $rhsVal;
  }

  sub subst {
    my $self = shift;
    my $lhs = $self->{lhs};
    my $lhsVal = $lhs->interp();
    my $rhs = $self->{rhs};
    my $rhsVal = $rhs->interp();
    my $from = shift;
    my $to = shift;

    

    if($lhsVal ne $lhsVal+0){ #check if lhs is number, if so move on to rhs
      #subst if idc (letters only)
      if($lhsVal =~ /^[a-zA-Z]+$/){
        $lhs = $lhs->subst($from, $to);
        $self->{lhs} = $lhs;
      }else{
        #else subst on body
        $lhs = $from->subst();
        $self->{lhs} = $lhs;
      }
    }

    if($rhsVal ne $rhsVal+0){ #check if rhs is number, if so move on to rhs
      #subst if idc (letters only)
      if($rhsVal =~ /^[a-zA-Z]+$/){
        $rhs = $rhs->subst($from, $to);
        $self->{rhs} = $rhs;
      }else{
        #else subst on body
        $rhs = $from->subst();
        $self->{rhs} = $rhs;
      }
    }

    return multC->new($lhs, $rhs);
  }


package fdC;

    sub new {
      my ($class, $id, $param, $body) = @_;
      return bless { id => $id, param => $param, body => $body }, $class;
    }

    sub formatDef {
      my $self = shift;

      my $id = $self->{id};
      my $param = $self->{param};
      my $body = $self->{body};


      my @fdcT = ($id, $param, $body);

      return @fdcT;

    }


package appC;
  
  use base ("numC", "idC", "fdC");

  sub new {
    my ($class, $name, $arg) = @_;
    return bless { name => $name, arg => $arg }, $class;
  }

  sub interp {
    my $self = shift;
    my $name = $self->{name};
    my $arg = $self->{arg};
    my @fdc = shift;
    my @fdcArr;

    #get array size
    my $arrSize = @fdc;

    my $found = undef;

    #find matching fundef
    for(my $i = 0; $i < $arrSize; $i++){
      my @fdcT = @fdc[$i]->formatDef();

      if($name eq @fdcT[$i]){
        $found = 1;
        @fdcArr = @fdcT;
        last;
      }
    }

    #what index of fundef array are we looking at
    if($found){
      my $id = @fdcArr[0];
      my $param = @fdcArr[1];
      my $body = @fdcArr[2];

      my $substBody = $self->subst($param, $arg, $body);

      return $substBody->interp();
    }else{
      return "Undefined Function!";
    }
  }

  sub subst {
    my $self = shift;
    my $name = $self->{name};
    my $arg = $self->{arg};

    my $from = shift;
    my $to = shift;
    my $body = shift;

    #print "$from, $to, $body";

    my $body = $body->subst($from, $to);

    return $body;
  }